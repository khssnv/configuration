"""Regression checks for retained observations, errors and report generation."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import collect
import render


ROOT = Path(__file__).resolve().parents[1]


class SnapshotTests(unittest.TestCase):
    def test_saved_evidence_survives_rendering(self):
        snapshots = render.load_snapshots(ROOT / "config-dump/data")
        report = render.render(snapshots, ROOT / "init-config-dump.md")
        for sections in snapshots.values():
            for _, data in sections.values():
                for probe in data["probes"].values():
                    for field in ("command", "stdout", "stderr"):
                        if probe.get(field):
                            formatted = "\n".join(line.rstrip() for line in probe[field].rstrip("\n").split("\n"))
                            self.assertIn(formatted, report)

    def test_timeout_retains_partial_output_and_other_probe_runs(self):
        timeout = subprocess.TimeoutExpired("probe", 30, output=b"partial\x00output", stderr=b"warning")
        success = subprocess.CompletedProcess([], 0, "second result", "")
        with patch.object(collect, "UNIT", {"slow": "slow", "next": "next"}), \
                patch.object(collect.subprocess, "run", side_effect=[timeout, success]):
            result = collect.collect("unit")
        self.assertEqual(result["probes"]["slow"]["stdout"], "partial\\0output")
        self.assertEqual(result["probes"]["slow"]["stderr"], "warning")
        self.assertIn("timeout", result["probes"]["slow"]["error"])
        self.assertEqual(result["probes"]["next"]["stdout"], "second result")
        details = render.probe_details(result)
        self.assertIn("timeout", details)
        self.assertIn("partial\\0output", details)
        self.assertIn("warning", details)

    def test_failed_or_missing_data_is_not_reported_as_a_value(self):
        data = {"section": "unit", "probes": {
            "serial": {"returncode": 1, "stdout": "misleading value", "stderr": "failure"},
        }}
        rows = render.unit_rows(data, None)
        self.assertIn("Not available", rows[0][1])
        self.assertNotIn("misleading value", rows[0][1])

    def test_selected_source_address(self):
        data = {"controller_link": {
            "route": {"command": "ip -j route get target", "stdout": '[{"prefsrc":"192.0.2.2"}]'},
            "address": {"stdout": '[{"addr_info":[{"local":"192.0.2.1","prefixlen":24},{"local":"192.0.2.2","prefixlen":24,"dynamic":true}]}]'},
        }}
        self.assertIn("192.0.2.2/24", render.controller_rows(data)[0][1])

    def test_unavailable_controller_tool_does_not_discard_robot_data(self):
        data = {"section": "unit", "probes": {"serial": {"stdout": "observed serial"}}}
        with patch.object(collect.subprocess, "run", side_effect=FileNotFoundError("ip missing")):
            result = collect.annotate(data, "rae-beta", "192.0.2.1")
        self.assertEqual(result["probes"]["serial"]["stdout"], "observed serial")
        self.assertIn("ip missing", result["controller_link"]["route"]["error"])

    def test_markdown_fence_and_table_values_cannot_escape_their_container(self):
        result = render.fenced("one\n```\n# text\n````\nlast")
        self.assertTrue(result.startswith("`````text\n"))
        self.assertTrue(result.endswith("\n`````\n\n"))
        self.assertEqual(render.code("a|<b>"), "<code>a&#124;&lt;b&gt;</code>")

    def test_invalid_annotations_and_failed_ssh_preserve_existing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "snapshot.json"
            output.write_text("retained")
            with patch.object(sys, "argv", ["collect.py", "unit", "--host", "192.0.2.1",
                                          "--unit-label", "rae-beta", "--output", str(output)]), \
                    patch.object(collect.subprocess, "run", return_value=subprocess.CompletedProcess([], 255, "")):
                with self.assertRaises(SystemExit):
                    collect.main()
            self.assertEqual(output.read_text(), "retained")
            with self.assertRaises(ValueError):
                collect.annotate({"section": "bad"}, "rae-beta", "192.0.2.1")

    def test_manual_ssh_saves_the_same_probe_data_and_controller_metadata(self):
        data = {"section": "unit", "probes": {
            "serial": {"command": "read serial", "returncode": 0,
                       "stdout": "EXAMPLE-SERIAL\n", "stderr": ""},
        }}
        raw = {"section": data["section"], "probes": data["probes"]}
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "snapshot.json"
            with patch.object(sys, "argv", ["collect.py", "unit", "--host", "192.0.2.1",
                                          "--unit-label", "rae-beta", "--output", str(output)]), \
                    patch.object(collect.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, json.dumps(raw))), \
                    patch.object(collect, "controller_command", return_value={"command": "ip", "error": "no route"}):
                collect.main()
            saved = json.loads(output.read_text())
            self.assertEqual(saved["probes"], raw["probes"])
            self.assertEqual(saved["unit"], "rae-beta")
            self.assertEqual(saved["ssh_target"], "192.0.2.1")
            self.assertIn("controller", saved["timestamp_source"])
            self.assertIn("no route", saved["controller_link"]["route"]["error"])

    def test_duplicate_snapshots_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ("rae-beta-unit.json", "rae-beta-copy.json"):
                Path(directory, name).write_text(json.dumps({"unit": "rae-beta", "section": "unit", "probes": {}}))
            with self.assertRaisesRegex(ValueError, "duplicate"):
                render.load_snapshots(Path(directory))

    def test_uncollected_unit_is_pending_and_links_resolve(self):
        snapshots = render.load_snapshots(ROOT / "config-dump/data")
        snapshots = {"rae-alpha": snapshots["rae-alpha"]}
        report = render.render(snapshots, ROOT / "init-config-dump.md")
        summary = report.split("### rae-beta", 1)[1].split("## Common observations", 1)[0]
        self.assertIn("collection pending", summary)
        for target in ("config-dump/README.md", "00-config-dump.yml",
                       "config-dump/data/rae-alpha-unit.json",
                       "config-dump/data/rae-alpha-common.json"):
            self.assertIn("](" + target + ")", report)
            self.assertTrue((ROOT / target).is_file())

    def test_regeneration_is_deterministic_and_leaves_identical_file_untouched(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "report.md"
            command = [sys.executable, str(ROOT / "config-dump/render.py"),
                       "--snapshots", str(ROOT / "config-dump/data"), "--output", str(output)]
            first = subprocess.run(command, check=True, capture_output=True, text=True)
            contents = output.read_bytes()
            modified = output.stat().st_mtime_ns
            second = subprocess.run(command, check=True, capture_output=True, text=True)
            self.assertTrue(first.stdout.startswith("changed:"))
            self.assertTrue(second.stdout.startswith("unchanged:"))
            self.assertEqual(output.read_bytes(), contents)
            self.assertEqual(output.stat().st_mtime_ns, modified)


if __name__ == "__main__":
    unittest.main()
