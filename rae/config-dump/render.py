#!/usr/bin/env python3
"""Render RAE collection snapshots as deterministic Markdown."""

import argparse
import html
import json
import os
from pathlib import Path
import re
import sys
import tempfile


def cell(value):
    return str(value).replace("|", "\\|").replace("\n", "<br>")


def table(headers, rows):
    if not headers or any(len(row) != len(headers) for row in rows):
        raise ValueError("table rows must match the header width")
    lines = ["| " + " | ".join(map(cell, headers)) + " |",
             "| " + " | ".join("---" for _ in headers) + " |"]
    lines.extend("| " + " | ".join(map(cell, row)) + " |" for row in rows)
    return "\n".join(lines) + "\n\n"


def code(value):
    # Values come from robot output and should not introduce Markdown markup.
    return "<code>" + html.escape(str(value)).replace("|", "&#124;") + "</code>"


def fenced(value, language="text"):
    longest = max((len(s) for s in re.findall(r"`+", value)), default=0)
    fence = "`" * max(3, longest + 1)
    formatted = "\n".join(line.rstrip() for line in value.rstrip("\n").split("\n"))
    return fence + language + "\n" + formatted + "\n" + fence + "\n\n"


def relative_link(path, output):
    return Path(os.path.relpath(path, output.parent)).as_posix()


def probe_output(snapshot, name):
    probe = (snapshot or {}).get("probes", {}).get(name, {})
    if probe.get("error") or probe.get("returncode") != 0:
        return ""
    return probe.get("stdout", "")


def first_line(value):
    return value.splitlines()[0] if value.splitlines() else "Not available"


def controller_rows(snapshot):
    link = snapshot.get("controller_link")
    if not link:
        return []
    rows = []
    route = link.get("route", {})
    address = link.get("address", {})
    source = "**computer**: " + code(route.get("command", "route unavailable"))
    if address.get("command"):
        source += "; " + code(address["command"])
    value = "Not available; inspect controller evidence below"
    try:
        route_data = json.loads(route["stdout"])[0]
        addresses = json.loads(address["stdout"])[0]["addr_info"]
        selected = next(a for a in addresses if a["local"] == route_data.get("prefsrc", route_data.get("src")))
        value = code("{local}/{prefixlen}".format(**selected))
        value += ", dynamic (DHCP)" if selected.get("dynamic") else ", no dynamic flag reported"
    except (KeyError, TypeError, ValueError, IndexError, StopIteration):
        pass
    rows.append(["Computer address used to reach RAE", value, source])
    if link.get("driver"):
        rows.append(["Computer link driver", code(link["driver"]), "**computer**: symlink " + code(link["driver_path"])])
    return rows


def unit_rows(snapshot, common):
    serial = first_line(probe_output(snapshot, "serial"))
    mac = first_line(probe_output(snapshot, "wifi_mac"))
    ssid = re.search(r"^\s*ssid (.*)$", probe_output(snapshot, "ap_ssid"), re.M)
    battery = probe_output(snapshot, "battery").splitlines()
    capacity = (battery[0] + " µAh (design " + battery[1] + " µAh)") if (
        len(battery) == 2 and all(v.isdigit() for v in battery)) else "Not available"
    boot = probe_output(snapshot, "boot")
    root = re.search(r"\broot=(\S+)", boot)
    slot = re.search(r"^mender_boot_part=(\d+)$", boot, re.M)
    boot_value = (root.group(1) + "; mender_boot_part=" + slot.group(1)) if root and slot else "Not available"
    rows = [[label, code(value), "`unit:" + probe + "` (commands below)"] for label, value, probe in (
        ("Serial number", serial, "serial"),
        ("Wi-Fi MAC (wlp1s0)", mac, "wifi_mac"),
        ("Access point SSID", ssid.group(1) if ssid else "Not reported (e.g. Wi-Fi client mode)", "ap_ssid"),
        ("Battery full charge capacity", capacity, "battery"),
        ("Active rootfs / Mender slot", boot_value, "boot"),
    )]
    rows.extend(controller_rows(snapshot))
    software = probe_output(common, "software")
    executable = next((line for line in software.splitlines() if line.startswith("/") and line.endswith("/lsusb")), None)
    if executable or "lsusb absent" in software.splitlines():
        rows.append(["lsusb", code(executable) if executable else "absent", "`common:software` (commands below)"])
    return rows


def probe_details(snapshot):
    result = []
    for name, probe in snapshot["probes"].items():
        status = probe.get("error", "shell exit status " + str(probe.get("returncode", "not recorded")))
        result.append("<details>\n<summary>" + html.escape(name + " — " + status) + "</summary>\n\n")
        result.append("Command:\n\n" + fenced(probe.get("command", "Not recorded"), "sh"))
        result.append("stdout:\n\n" + fenced(probe.get("stdout", "") or "(empty)"))
        result.append("stderr:\n\n" + fenced(probe.get("stderr", "") or "(empty)"))
        result.append("</details>\n\n")
    return "".join(result)


def render(snapshots, output):
    root = Path(__file__).resolve().parents[1]
    result = ["# Luxonis RAE configuration dump\n\n",
              "<!-- Generated by config-dump/render.py. Edit config-dump/data or the renderer, then regenerate. -->\n\n",
              "`config-dump` was created to preserve the initial factory configuration before network setup "
              "or other configuration changes. This report contains observations from the current collection. "
              "A snapshot records the state at collection; it does not prove that a factory reset occurred. "
              "Physical labels `rae-alpha` and `rae-beta` are selected by the operator. "
              "Both robots use factory hostname `rae` and USB address `192.168.197.55`.\n\n",
              "Platform strings such as `keembay.target`, `intel,keembay-evm`, "
              "Mender `device_type=keembay` and literal `/etc/hosts` entries remain factory values.\n\n",
              "Collection and regeneration commands: [tool documentation](" +
              relative_link(root / "config-dump/README.md", output) + "). "
              "The [collection playbook](" + relative_link(root / "00-config-dump.yml", output) +
              ") uses the same inventory as network setup.\n\n",
              "Commands and output below come from JSON snapshots. Probe shell status applies to the last "
              "command; always inspect stderr because an earlier failure may be masked. "
              "Missing results are shown as unavailable. Runtime values, including memory, storage usage, "
              "battery estimates, ports and active A/B slot, can change. "
              "Controller timestamps are used because the robot clock can be unsynchronized.\n\n",
              "The collector excludes password databases, SSH keys/authorized keys, hostapd/WPA credentials, "
              "Mender/RobotHub configuration, environment scripts and EEPROM contents.\n\n",
              "## Unit-specific data\n\n"]
    units = ("rae-alpha", "rae-beta")
    for unit in units:
        result.append("### " + unit + "\n\n")
        live = snapshots.get(unit, {})
        if "unit" in live:
            path, data = live["unit"]
            result.append("Collected " + code(data.get("collected_at_utc", "timestamp unavailable")) +
                          " via " + code(data.get("ssh_target", "target unavailable")) +
                          ". [Unit JSON](" + relative_link(path, output) + ").\n\n")
            common = live.get("common", (None, None))[1]
            result.append(table(["Item", "Value", "Source / command"], unit_rows(data, common)))
            result.append(probe_details(data))
            controller = data.get("controller_link")
            if controller:
                result.append("<details>\n<summary>Controller link evidence</summary>\n\n" +
                              fenced(json.dumps(controller, indent=2), "json") + "</details>\n\n")
        else:
            result.append("Unit snapshot not available; collection pending.\n\n")
    result.append("## Common observations\n\n"
                  "These checks cover the baseline, but their results belong to the named robot. "
                  "Expand a check to inspect its exact command, stdout and stderr.\n\n")
    for unit in units:
        common = snapshots.get(unit, {}).get("common")
        if not common:
            continue
        path, data = common
        result.append("### " + unit + "\n\nCollected " + code(data.get("collected_at_utc", "timestamp unavailable")) +
                      ". [Common JSON](" + relative_link(path, output) + ").\n\n")
        result.append(table(["Check", "Shell exit status / error", "stderr"], [
            [name, code(probe.get("error", probe.get("returncode", "not recorded"))),
             "recorded; inspect below" if probe.get("stderr") else "empty"]
            for name, probe in data["probes"].items()]))
        result.append(probe_details(data))
    return "".join(result).rstrip() + "\n"


def load_snapshots(directory):
    snapshots = {}
    for path in sorted(directory.glob("rae-*.json")):
        data = json.loads(path.read_text())
        if not isinstance(data, dict):
            raise ValueError(str(path) + ": expected a JSON object")
        unit = data.get("unit")
        if unit not in ("rae-alpha", "rae-beta"):
            raise ValueError(str(path) + ": expected unit rae-alpha or rae-beta")
        section = data.get("section")
        if section not in ("common", "unit") or not isinstance(data.get("probes"), dict):
            raise ValueError(str(path) + ": expected common or unit snapshot")
        for name, probe in data["probes"].items():
            if not isinstance(probe, dict) or not isinstance(probe.get("command"), str):
                raise ValueError(str(path) + ": invalid probe " + name)
            if not isinstance(probe.get("returncode"), int) and not isinstance(probe.get("error"), str):
                raise ValueError(str(path) + ": missing result status for " + name)
            if any(not isinstance(probe.get(field, ""), str) for field in ("stdout", "stderr")):
                raise ValueError(str(path) + ": expected text output for " + name)
        if section in snapshots.setdefault(unit, {}):
            raise ValueError("duplicate " + section + " snapshot for " + unit)
        snapshots[unit][section] = (path, data)
    if not snapshots:
        raise ValueError("no RAE snapshots found in " + str(directory))
    return snapshots


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshots", type=Path, default=root / "config-dump/data")
    parser.add_argument("--output", type=Path, default=root / "init-config-dump.md")
    args = parser.parse_args()
    snapshots = load_snapshots(args.snapshots)
    content = render(snapshots, args.output)
    # Report changed/unchanged for Ansible and avoid touching identical output.
    if args.output.exists() and args.output.read_text() == content:
        print("unchanged: " + str(args.output))
        return
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.output.parent,
                                         prefix="." + args.output.name, delete=False) as stream:
            temporary = stream.name
            stream.write(content)
        os.replace(temporary, args.output)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)
    print("changed: " + str(args.output))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit(str(error))
