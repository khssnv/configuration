#!/usr/bin/env python3
"""Copy selected local changes between worktrees, preserving the source.

Read SOURCE/.worktreeinclude as gitignore-style inclusion patterns; do nothing
if absent. Copy staged/unstaged changes combined relative to SOURCE HEAD,
including staged additions and deletions, plus selected untracked files.
Ignored files are handled separately by wt step copy-ignored.

SOURCE and DESTINATION must be roots of different worktrees in one repository.
Neither index changes; copied changes are unstaged and new files are untracked.
Validate before writing; reject symlinks, untracked destination collisions and
conflicting patches. --dry-run performs the same checks without writing.
Untracked copies retain permissions and timestamps. Concurrent edits or
filesystem errors can leave partial results; copying is not transactional.

Requires Python 3.10+, pathspec and Git.
Exit status: 0 on success (including no selected files), 1 on copy errors,
2 on invalid arguments.
"""

import argparse
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import subprocess

from pathspec import GitIgnoreSpec


DIFF_OPTIONS = (
    "--no-ext-diff",
    "--no-textconv",
    "--no-renames",
    "--no-color",
    "--src-prefix=a/",
    "--dst-prefix=b/",
)


class CopyError(Exception):
    pass


def git(root: Path, *args: str, data: bytes | None = None) -> bytes:
    # Disable optional index refreshes: even cached stat information stays intact.
    result = subprocess.run(
        ["git", "--no-optional-locks", "-C", str(root), *args],
        input=data,
        capture_output=True,
    )
    if result.returncode:
        raise CopyError(result.stderr.decode(errors="replace").strip())
    return result.stdout


def decode_paths(output: bytes) -> list[str]:
    return [os.fsdecode(name) for name in output.split(b"\0") if name]


def git_diff(root: Path, names: list[str], *options: str) -> bytes:
    """Diff literal paths only; an empty selection must never diff all files."""
    if not names:
        return b""
    literals = [f":(literal){name}" for name in names]
    return git(root, "diff", *DIFF_OPTIONS, *options, "--", *literals)


def regular_file(root: Path, name: str, *, allow_missing: bool = False) -> Path:
    """Validate every path component without following symbolic links."""
    relative = PurePosixPath(name)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        raise CopyError("invalid relative path")
    path = root
    for index, part in enumerate(relative.parts):
        path /= part
        try:
            mode = path.lstat().st_mode
        except FileNotFoundError:
            if allow_missing:
                return root / name
            raise CopyError(f"source file is missing: {name!r}") from None
        is_leaf = index == len(relative.parts) - 1
        if stat.S_ISLNK(mode):
            raise CopyError(f"symbolic links are unsupported: {name!r}")
        if not (stat.S_ISREG(mode) if is_leaf else stat.S_ISDIR(mode)):
            raise CopyError(f"not a regular file path: {name!r}")
    return path


def load_include(source: Path) -> GitIgnoreSpec | None:
    """Load inclusion patterns, or return None if .worktreeinclude is absent.

    Use docs/ then !docs/drafts/ to exclude drafts: GitIgnoreSpec gives
    docs/** file matches priority over directory negations.
    """
    include = regular_file(source, ".worktreeinclude", allow_missing=True)
    if not include.exists():
        return None
    with include.open(encoding="utf-8") as stream:
        # Keep escaped trailing spaces intact when pathspec parses each pattern.
        return GitIgnoreSpec.from_lines(line.rstrip("\r\n") for line in stream)


def validate_worktrees(source: Path, destination: Path) -> None:
    for root in (source, destination):
        actual_root = Path(
            os.fsdecode(git(root, "rev-parse", "--show-toplevel")).rstrip("\n")
        ).resolve()
        if actual_root != root:
            raise CopyError("source and destination must be worktree roots")
    common = [
        git(root, "rev-parse", "--path-format=absolute", "--git-common-dir").rstrip(
            b"\n"
        )
        for root in (source, destination)
    ]
    if common[0] != common[1]:
        raise CopyError("source and destination must belong to the same repository")


def selected_paths(root: Path, spec: GitIgnoreSpec, *options: str) -> list[str]:
    """Select Git paths by inclusion patterns without extra filename exclusions."""
    names = decode_paths(git(root, "ls-files", "-z", *options))
    return sorted(spec.match_files(names))


def validate_untracked(source: Path, destination: Path, names: list[str]) -> None:
    for name in names:
        regular_file(source, name)
        target = regular_file(destination, name, allow_missing=True)
        if target.exists():
            raise CopyError(
                f"destination already contains an untracked source path: {name!r}"
            )


def prepare_patch(
    source: Path, destination: Path, tracked: list[str]
) -> tuple[bytes, int]:
    """Build and check the combined HEAD-to-worktree patch before writing."""
    for name in tracked:
        regular_file(source, name, allow_missing=True)
    changed = decode_paths(git_diff(source, tracked, "HEAD", "--name-only", "-z"))
    if not changed:
        return b"", 0
    for name in changed:
        regular_file(destination, name, allow_missing=True)
    for options in ((), ("--cached",)):
        if git_diff(destination, changed, *options, "--name-only", "-z"):
            raise CopyError("destination has local changes in selected tracked files")
    patch = git_diff(source, changed, "HEAD", "--binary")
    git(destination, "apply", "--check", "-", data=patch)
    return patch, len(changed)


def copy_untracked_file(source: Path, destination: Path, name: str) -> None:
    """Create one file exclusively, preserving its mode and timestamps."""
    origin = regular_file(source, name)
    target = regular_file(destination, name, allow_missing=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    # Do not follow a source symlink or overwrite an existing destination.
    with (
        os.fdopen(os.open(origin, os.O_RDONLY | os.O_NOFOLLOW), "rb") as reader,
        target.open("xb") as writer,
    ):
        shutil.copyfileobj(reader, writer)
        writer.flush()
        metadata = os.fstat(reader.fileno())
        os.fchmod(writer.fileno(), stat.S_IMODE(metadata.st_mode))
        os.utime(writer.fileno(), ns=(metadata.st_atime_ns, metadata.st_mtime_ns))


def copy_local(
    source: str | Path, destination: str | Path, dry_run: bool = False
) -> tuple[int, int]:
    """Validate first, then copy; return counts of changed and untracked files."""
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if source == destination:
        raise CopyError("source and destination must be different worktrees")
    spec = load_include(source)
    if spec is None:
        return 0, 0

    validate_worktrees(source, destination)
    # Include HEAD paths so staged deletions remain eligible for copying.
    tracked = selected_paths(source, spec, "--cached", "--with-tree=HEAD")
    untracked = selected_paths(source, spec, "--others", "--exclude-standard")
    validate_untracked(source, destination, untracked)
    patch, changed_count = prepare_patch(source, destination, tracked)

    if not dry_run:
        if patch:
            git(destination, "apply", "-", data=patch)
        for name in untracked:
            copy_untracked_file(source, destination, name)
    return changed_count, len(untracked)


def main():
    """Report copy counts on stdout and errors on stderr."""
    parser = argparse.ArgumentParser(
        prog="wt-copy-local",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "source", metavar="SOURCE", help="source worktree root containing .worktreeinclude"
    )
    parser.add_argument(
        "destination", metavar="DESTINATION", help="existing destination worktree root"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="validate and report without writing"
    )
    args = parser.parse_args()
    try:
        tracked, untracked = copy_local(args.source, args.destination, args.dry_run)
    except (CopyError, OSError, ValueError) as error:
        parser.exit(1, f"wt-copy-local: {error}\n")
    action = "would copy" if args.dry_run else "copied"
    print(
        f"wt-copy-local: {action} {tracked} tracked changes and {untracked} untracked files"
    )


if __name__ == "__main__":
    main()
