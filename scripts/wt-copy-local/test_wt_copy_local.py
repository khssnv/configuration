"""Integration checks against temporary Git repositories; no personal files are used."""

import importlib.util
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "wt_copy_local", Path(__file__).resolve().with_name("wt-copy-local.py")
)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class CopyLocalTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="wt-copy-local-test-")
        self.root = Path(self.temporary.name)
        self.source = self.root / "source space's"
        self.destination = self.root / "destination"
        self.source.mkdir()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("config", "commit.gpgsign", "false")
        for name, content in {
            ".gitignore": b".cache/\n",
            "asset.bin": b"original\0binary",
            "gone.txt": b"delete me\n",
            "script.sh": b"#!/bin/sh\nexit 0\n",
            "other.txt": b"keep original\n",
        }.items():
            (self.source / name).write_bytes(content)
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        self.git("worktree", "add", "-qb", "task", str(self.destination))
        self.include(".gitignore\ndocs/\nasset.bin\ngone.txt\nscript.sh\n.cache/\n")

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args, root=None):
        return subprocess.check_output(
            ["git", "--no-optional-locks", "-C", str(root or self.source), *args],
            stderr=subprocess.PIPE,
        )

    def include(self, content):
        (self.source / ".worktreeinclude").write_text(content)

    def write(self, name, content, root=None):
        path = (root or self.source) / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

    def snapshot(self, root):
        entries = {}
        for path in root.rglob("*"):
            relative = path.relative_to(root)
            if ".git" in relative.parts:
                continue
            if path.is_symlink():
                entries[str(relative)] = ("link", os.readlink(path))
            elif path.is_file():
                entries[str(relative)] = (
                    path.read_bytes(),
                    stat.S_IMODE(path.stat().st_mode),
                )
        index = Path(
            os.fsdecode(self.git("rev-parse", "--git-path", "index", root=root)).rstrip(
                "\n"
            )
        )
        if not index.is_absolute():
            index = root / index
        return entries, index.read_bytes()

    def test_copy_preserves_source_and_indexes(self):
        self.write(".gitignore", b".cache/\nscratch/\n")
        self.write("asset.bin", b"changed\0binary\xff")
        (self.source / "gone.txt").unlink()
        (self.source / "script.sh").chmod(0o755)
        for name in ("docs/with space.md", "docs/line\nbreak.md", "docs/[literal].md"):
            self.write(name, b"untracked\n")
        self.write(".cache/artifact", b"ignored\n")
        self.write("other.txt", b"unselected change\n")
        before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]

        self.assertEqual(helper.copy_local(self.source, self.destination), (4, 3))

        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        self.assertEqual(
            (self.destination / ".gitignore").read_bytes(), b".cache/\nscratch/\n"
        )
        self.assertEqual(
            (self.destination / "asset.bin").read_bytes(), b"changed\0binary\xff"
        )
        self.assertFalse((self.destination / "gone.txt").exists())
        self.assertEqual(
            stat.S_IMODE((self.destination / "script.sh").stat().st_mode), 0o755
        )
        self.assertEqual(
            (self.destination / "other.txt").read_bytes(), b"keep original\n"
        )
        self.assertFalse((self.destination / ".cache").exists())
        for name in ("docs/with space.md", "docs/line\nbreak.md", "docs/[literal].md"):
            self.assertEqual((self.destination / name).read_bytes(), b"untracked\n")

    def test_repository_specific_patterns_and_negation(self):
        self.include("# Project policy\n/docs/\n!docs/drafts/\n")
        self.write("docs/keep.md", b"include\n")
        self.write("docs/drafts/skip.md", b"exclude\n")
        self.write("other/docs/skip.md", b"anchored exclusion\n")
        self.write(".gitignore", b".cache/\nnot-selected/\n")
        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 1))
        self.assertTrue((self.destination / "docs/keep.md").exists())
        self.assertFalse((self.destination / "docs/drafts").exists())
        self.assertFalse((self.destination / "other").exists())
        self.assertEqual((self.destination / ".gitignore").read_bytes(), b".cache/\n")

    def test_pattern_escapes_wildcards_and_reinclusion(self):
        files = (
            "docs/keep.md",
            "docs/drafts/skip.md",
            "docs/drafts/keep.md",
            "docs/space file.md",
            "docs/trailing space ",
            "#literal.md",
            "#keep.md",
            "!literal.md",
            "!keep.md",
        )
        for name in files:
            self.write(name, b"pattern fixture\n")
        self.include(
            "# Comment\n[d]ocs/\n!docs/drafts/\ndocs/drafts/**/keep.md\n"
            "!docs/space\\ file.md\n!docs/trailing space\\ \n"
            "\\#*.md\n!#literal.md\n\\!*.md\n!!literal.md"
        )
        before = self.snapshot(self.source)
        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 4))
        self.assertEqual(self.snapshot(self.source), before)
        included = {"docs/keep.md", "docs/drafts/keep.md", "#keep.md", "!keep.md"}
        for name in files:
            self.assertEqual((self.destination / name).exists(), name in included)

    def test_glob_takes_priority_over_directory_negation(self):
        self.include("docs/**\n!docs/drafts/\n")
        self.write("docs/keep.md", b"included fixture\n")
        self.write("docs/drafts/skip.md", b"directory negation fixture\n")
        before = self.snapshot(self.source)
        # GitIgnoreSpec gives the file glob priority over the directory negation.
        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 2))
        self.assertEqual(self.snapshot(self.source), before)
        self.assertTrue((self.destination / "docs/keep.md").exists())
        self.assertTrue((self.destination / "docs/drafts/skip.md").exists())

    def test_untracked_metadata_and_newline_parent(self):
        name = "docs/parent\n/new file.md"
        self.write(name, b"binary fixture\0\xff")
        source_file = self.source / name
        source_file.chmod(0o751)
        timestamp = 1_700_000_000_123_456_789
        os.utime(source_file, ns=(timestamp, timestamp))
        before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]
        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 1))
        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        destination_file = self.destination / name
        self.assertEqual(destination_file.read_bytes(), b"binary fixture\0\xff")
        self.assertEqual(stat.S_IMODE(destination_file.stat().st_mode), 0o751)
        self.assertEqual(destination_file.stat().st_mtime_ns, timestamp)

    def test_literal_tracked_paths_and_example_file(self):
        self.write("docs/[literal].md", b"base\n")
        self.git("add", "docs")
        self.git("commit", "-qm", "literal path")
        self.git("reset", "--hard", "main", root=self.destination)
        self.write("docs/[literal].md", b"changed\n")
        self.write("docs/.env.example", b"EXAMPLE=placeholder\n")
        self.assertEqual(helper.copy_local(self.source, self.destination), (1, 1))
        self.assertEqual(
            (self.destination / "docs/[literal].md").read_bytes(), b"changed\n"
        )
        self.assertTrue((self.destination / "docs/.env.example").exists())

    def test_missing_include_and_dry_run_do_not_write(self):
        self.write(".gitignore", b".cache/\nscratch/\n")
        self.git("add", ".gitignore")
        self.write("docs/new.md", b"new\n")
        source_before = self.snapshot(self.source)
        before = self.snapshot(self.destination)
        self.assertEqual(
            helper.copy_local(self.source, self.destination, dry_run=True), (1, 1)
        )
        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination), before)
        (self.source / ".worktreeinclude").unlink()
        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 0))
        self.assertEqual(self.snapshot(self.destination), before)

    def test_empty_selection_does_not_copy_unselected_changes(self):
        self.include("# No selected files\n")
        self.write(".gitignore", b".cache/\nscratch/\n")
        self.git("add", ".gitignore")
        self.write("docs/new.md", b"new\n")
        source_before = self.snapshot(self.source)
        destination_before = self.snapshot(self.destination)

        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 0))

        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination), destination_before)

    def test_untracked_collision_aborts_before_applying_patch(self):
        self.write(".gitignore", b".cache/\nscratch/\n")
        self.write("docs/new.md", b"source\n")
        self.write("docs/new.md", b"destination\n", self.destination)
        source_before = self.snapshot(self.source)
        destination_before = self.snapshot(self.destination)
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)
        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination), destination_before)

    def test_patch_conflict_aborts_before_copying_untracked(self):
        self.write(".gitignore", b"source-cache/\n")
        self.write("docs/new.md", b"source\n")
        self.write(".gitignore", b"destination-cache/\n", self.destination)
        self.git("add", ".gitignore", root=self.destination)
        self.git("commit", "-qm", "different base", root=self.destination)
        before = self.snapshot(self.destination)
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)
        self.assertEqual(self.snapshot(self.destination), before)

    def test_staged_changes_preserve_source_and_indexes(self):
        self.write(".gitignore", b".cache/\nstaged/\n")
        self.write("asset.bin", b"staged\0binary\xff")
        (self.source / "gone.txt").unlink()
        (self.source / "script.sh").chmod(0o755)
        added = ("docs/with space.md", "docs/line\nbreak.md", "docs/[literal].md")
        for name in added:
            self.write(name, b"staged addition\0\xff")
        self.write("other.txt", b"unselected staged change\n")
        self.git(
            "add", ".gitignore", "asset.bin", "gone.txt", "script.sh", "docs", "other.txt"
        )
        self.write("docs/untracked.md", b"untracked\n")
        before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]

        self.assertEqual(helper.copy_local(self.source, self.destination), (7, 1))

        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        self.assertEqual(
            (self.destination / ".gitignore").read_bytes(), b".cache/\nstaged/\n"
        )
        self.assertEqual(
            (self.destination / "asset.bin").read_bytes(), b"staged\0binary\xff"
        )
        self.assertFalse((self.destination / "gone.txt").exists())
        self.assertEqual(
            stat.S_IMODE((self.destination / "script.sh").stat().st_mode), 0o755
        )
        for name in added:
            self.assertEqual(
                (self.destination / name).read_bytes(), b"staged addition\0\xff"
            )
        self.assertEqual(
            (self.destination / "docs/untracked.md").read_bytes(), b"untracked\n"
        )
        self.assertEqual(
            (self.destination / "other.txt").read_bytes(), b"keep original\n"
        )

    def test_mixed_changes_copy_final_worktree_contents(self):
        self.write(".gitignore", b".cache/\nstaged/\n")
        self.write("docs/new.md", b"staged addition\n")
        self.git("add", ".gitignore", "docs/new.md")
        self.write(".gitignore", b".cache/\nunstaged/\n")
        self.write("docs/new.md", b"unstaged addition\n")
        before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]

        self.assertEqual(helper.copy_local(self.source, self.destination), (2, 0))

        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        self.assertEqual(
            (self.destination / ".gitignore").read_bytes(), b".cache/\nunstaged/\n"
        )
        self.assertEqual(
            (self.destination / "docs/new.md").read_bytes(), b"unstaged addition\n"
        )

    def test_staged_changes_undone_in_worktree_copy_nothing(self):
        self.write(".gitignore", b".cache/\nstaged/\n")
        self.git("add", ".gitignore")
        self.write(".gitignore", b".cache/\n")
        self.write("docs/new.md", b"staged addition\n")
        self.git("add", "docs/new.md")
        (self.source / "docs/new.md").unlink()
        before = self.snapshot(self.source)
        destination_before = self.snapshot(self.destination)

        self.assertEqual(helper.copy_local(self.source, self.destination), (0, 0))

        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination), destination_before)

    def test_staged_rename_copies_both_paths(self):
        (self.source / "docs").mkdir()
        self.git("mv", "gone.txt", "docs/renamed.md")
        before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]

        self.assertEqual(helper.copy_local(self.source, self.destination), (2, 0))

        self.assertEqual(self.snapshot(self.source), before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        self.assertFalse((self.destination / "gone.txt").exists())
        self.assertEqual(
            (self.destination / "docs/renamed.md").read_bytes(), b"delete me\n"
        )

    def test_staged_addition_collision_aborts_before_writing(self):
        self.write(".gitignore", b".cache/\nstaged/\n")
        self.write("docs/new.md", b"staged addition\n")
        self.git("add", ".gitignore", "docs/new.md")
        self.write("docs/new.md", b"destination\n", self.destination)
        self.write("docs/untracked.md", b"untracked\n")
        source_before = self.snapshot(self.source)
        destination_before = self.snapshot(self.destination)

        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)

        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination), destination_before)

    def test_symlink_and_destination_parent_collision(self):
        outside = self.root / "outside"
        outside.mkdir()
        (outside / "example.md").write_bytes(b"outside\n")
        self.write("docs/new.md", b"source\n")
        (self.destination / "docs").symlink_to(outside, target_is_directory=True)
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)
        self.assertFalse((outside / "new.md").exists())
        (self.destination / "docs").unlink()
        (self.source / "docs/link.md").symlink_to(outside / "example.md")
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)
        self.assertFalse((self.destination / "docs").exists())

    def test_include_controls_previously_excluded_names(self):
        self.include("docs/\n.npmrc\n!docs/skip.pem\n")
        self.write("docs/public.pem", b"public certificate fixture\n")
        self.git("add", "docs/public.pem")
        self.git("commit", "-qm", "public fixture")
        self.git("reset", "--hard", "main", root=self.destination)
        self.write("docs/public.pem", b"changed public certificate fixture\n")
        self.write("docs/public.key", b"public key fixture\n")
        self.write(".npmrc", b"registry=https://registry.npmjs.org/\n")
        self.write("docs/skip.pem", b"excluded public certificate fixture\n")
        source_before = self.snapshot(self.source)
        destination_index = self.snapshot(self.destination)[1]

        self.assertEqual(helper.copy_local(self.source, self.destination), (1, 2))

        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination)[1], destination_index)
        for name in ("docs/public.pem", "docs/public.key", ".npmrc"):
            self.assertEqual(
                (self.destination / name).read_bytes(),
                (self.source / name).read_bytes(),
            )
        self.assertFalse((self.destination / "docs/skip.pem").exists())

    def test_destination_changes_and_same_worktree_rejected(self):
        self.write(".gitignore", b".cache/\nsource/\n")
        self.write(".gitignore", b".cache/\ndestination/\n", self.destination)
        before = self.snapshot(self.destination)
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)
        self.assertEqual(self.snapshot(self.destination), before)
        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.source)

    def test_staged_destination_changes_abort_before_writing(self):
        self.write(".gitignore", b".cache/\nsource/\n")
        self.git("add", ".gitignore")
        self.write("docs/new.md", b"new\n")
        self.write(".gitignore", b".cache/\nstaged/\n", self.destination)
        self.git("add", ".gitignore", root=self.destination)
        before = self.snapshot(self.destination)

        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)

        self.assertEqual(self.snapshot(self.destination), before)

    def test_dry_run_rejects_conflicts_without_writing(self):
        self.write(".gitignore", b".cache/\nsource/\n")
        self.write("docs/new.md", b"source\n")
        self.write("docs/new.md", b"destination\n", self.destination)
        source_before = self.snapshot(self.source)
        destination_before = self.snapshot(self.destination)

        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination, dry_run=True)

        self.assertEqual(self.snapshot(self.source), source_before)
        self.assertEqual(self.snapshot(self.destination), destination_before)

    def test_worktree_subdirectories_and_other_repositories_rejected(self):
        subdirectory = self.destination / "nested"
        subdirectory.mkdir()
        other = self.root / "other repository"
        other.mkdir()
        self.git("init", "-q", "-b", "main", root=other)
        before = self.snapshot(self.destination)

        for destination in (subdirectory, other):
            with self.subTest(destination=destination):
                with self.assertRaises(helper.CopyError):
                    helper.copy_local(self.source, destination)

        self.assertEqual(self.snapshot(self.destination), before)
        self.assertEqual(list(other.iterdir()), [other / ".git"])

    def test_include_symlink_rejected(self):
        include = self.source / ".worktreeinclude"
        include.unlink()
        include.symlink_to(self.source / ".gitignore")
        before = self.snapshot(self.destination)

        with self.assertRaises(helper.CopyError):
            helper.copy_local(self.source, self.destination)

        self.assertEqual(self.snapshot(self.destination), before)

    def test_cli_reports_counts_and_errors(self):
        self.write(".gitignore", b".cache/\nscratch/\n")
        self.git("add", ".gitignore")
        self.write("docs/new.md", b"new\n")
        command = [
            sys.executable,
            str(Path(__file__).resolve().with_name("wt-copy-local.py")),
            str(self.source),
            str(self.destination),
        ]
        before = self.snapshot(self.destination)
        preview = subprocess.run(
            [*command, "--dry-run"], capture_output=True, text=True
        )
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertEqual(
            preview.stdout,
            "wt-copy-local: would copy 1 tracked changes and 1 untracked files\n",
        )
        self.assertEqual(self.snapshot(self.destination), before)

        copied = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(copied.returncode, 0, copied.stderr)
        self.assertEqual(
            copied.stdout,
            "wt-copy-local: copied 1 tracked changes and 1 untracked files\n",
        )
        self.assertEqual(
            (self.destination / ".gitignore").read_bytes(), b".cache/\nscratch/\n"
        )
        self.assertEqual((self.destination / "docs/new.md").read_bytes(), b"new\n")

        before = self.snapshot(self.destination)
        rejected = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(rejected.returncode, 1)
        self.assertEqual(rejected.stdout, "")
        self.assertIn("wt-copy-local: destination already contains", rejected.stderr)
        self.assertNotIn("Traceback", rejected.stderr)
        self.assertEqual(self.snapshot(self.destination), before)


if __name__ == "__main__":
    unittest.main()
