#!/usr/bin/env python3
"""Read-only, allowlisted RAE probes; compatible with its Python 3.8.

Use --host for SSH collection. Never dump credentials, environment,
hostapd/WPA configuration, SSH keys, EEPROM contents or RobotHub config/data.
"""

import argparse
from datetime import datetime, timezone
import ipaddress
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


COMMON = {
    "identity": """
cat /sys/firmware/devicetree/base/model /sys/firmware/devicetree/base/compatible
fw_printenv board soc
hostname
cat /etc/hostname /etc/hosts /var/lib/mender/device_type /factory/version
""",
    "os": """
cat /etc/os-release /etc/mender/artifact_info
uname -a
cat /proc/version
getconf GNU_LIBC_VERSION
systemctl --version
systemctl get-default
openssl version
ssh -V
bash --version | head -n 1
readlink /etc/localtime
locale
""",
    "hardware": """
cat /proc/cpuinfo
for f in /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; do echo "$f"; cat "$f"; done
head -n 5 /proc/meminfo
cat /proc/swaps
lsblk -b -o NAME,SIZE,TYPE
for d in /sys/bus/pci/devices/*; do echo "$d"; cat "$d/vendor" "$d/device"; readlink "$d/driver"; done
for d in /sys/bus/usb/devices/*; do echo "$d"; for f in idVendor idProduct product speed; do [ ! -f "$d/$f" ] || cat "$d/$f"; done; done
for d in /sys/class/udc/*; do echo "$d"; cat "$d/current_speed" "$d/state"; done
ls -l /dev/dri /dev/watchdog* /sys/class/rtc
for f in /sys/class/watchdog/watchdog*/identity /sys/class/misc/hw_random/rng_current; do [ ! -f "$f" ] || { echo "$f"; cat "$f"; }; done
hwclock --show
ls /lib/firmware/vpu* /lib/firmware/intel/vpux
find /usr/lib -maxdepth 2 -name '*hantro*' -print
modinfo vpumgr
lsmod
""",
    "cameras": """
for d in /sys/class/video4linux/*; do echo "$d"; cat "$d/name"; readlink -f "$d/device"; done
for d in /sys/bus/i2c/devices/*; do [ ! -f "$d/name" ] || { echo "$d"; cat "$d/name"; }; done
v4l2-ctl --list-devices
ls /dev/media* /dev/video*
""",
    "peripherals": """
for bus in i2c spi platform; do
  for d in /sys/bus/$bus/devices/*; do
    [ ! -L "$d/driver" ] || { echo "$d"; readlink "$d/driver"; }
  done
done
for f in /sys/class/graphics/fb0/name /sys/class/graphics/fb0/virtual_size /sys/class/graphics/fb0/bits_per_pixel /sys/class/pwm/pwmchip*/npwm /sys/class/gpio/gpiochip*/ngpio /sys/class/power_supply/bq27441-0/technology /sys/class/power_supply/bq27441-0/charge_full_design /sys/class/thermal/thermal_zone*/type; do echo "$f"; cat "$f"; done
ls -l /dev/spidev* /dev/input/event* /dev/ttyS* /sys/class/pwm/pwmchip*/
cat /proc/asound/cards /proc/asound/pcm /proc/bus/input/devices
aplay -l
arecord -l
ls /sys/class/leds
cat /proc/cmdline
""",
    "gpio": "gpioinfo",
    "storage": "lsblk -b -o NAME,PARTLABEL,LABEL,SIZE,FSTYPE,MOUNTPOINT; df -B1 / /data",
    "mounts": "cat /proc/mounts; find /data/overlay/current -maxdepth 3 -printf '%y %p\\n'; find /factory/etc -maxdepth 1 -printf '%y %p\\n'",
    "boot": """
cat /proc/cmdline
fw_printenv mender_boot_part bootlimit upgrade_available bootdelay baudrate is_secure
mender --version
systemctl show mender-commit.service -p ExecStart -p ActiveState -p UnitFileState
""",
    "recovery": "fw_printenv os_recovery_if_needed_cmd recoverycmd recoveryeth",
    "network": """
ip -brief address
ip route
bridge link
ls -la /etc/systemd/network
cat /lib/systemd/network/80-wifi.network /lib/systemd/network/80-wired.network
cat /etc/scripts/start-usb-ethernet.sh
""",
    "usb": """
for f in /sys/kernel/config/usb_gadget/usbnet/idVendor /sys/kernel/config/usb_gadget/usbnet/idProduct /sys/kernel/config/usb_gadget/usbnet/strings/0x409/manufacturer /sys/kernel/config/usb_gadget/usbnet/strings/0x409/product; do echo "$f"; cat "$f"; done
ls /sys/kernel/config/usb_gadget/usbnet/functions
cat /etc/scripts/create-dual-rndis-and-ncm.sh
cat /etc/dnsmasq.conf
""",
    "wifi": """
systemctl show wifi.service hostapd.service wpa_supplicant@wlp1s0.service wpa_supplicant-nl80211@wlp1s0.service -p Id -p ActiveState -p UnitFileState -p Restart -p ExecStart
cat /usr/bin/wifi-init.sh /etc/wifi.conf
iw dev wlp1s0 info
iw reg get
iw list
cat /etc/dnsmasq.conf
""",
    "dns": """
cat /etc/dnsmasq.conf /etc/systemd/timesyncd.conf
resolvectl status
timedatectl
date -u
cat /etc/iptables/iptables.rules
iptables-save
if command -v nft; then :; else echo 'nft absent'; fi
""",
    # Never include process arguments or environment in listening/RSS probes.
    "listeners": "if command -v ss >/dev/null; then ss -lntup; else netstat -lntup; fi",
    "access": """
cat /etc/ssh/sshd_config
cat /etc/sudoers
find /etc/sudoers.d -maxdepth 1 -type f -printf '%f\\n'
systemctl show serial-getty@ttyS0.service serial-getty@ttyS3.service getty@tty1.service -p Id -p ActiveState -p UnitFileState
""",
    "accounts": "getent passwd; getent group",
    "services": """
systemctl list-unit-files --state=enabled --no-pager
systemctl list-units --type=service --all --no-pager
for unit in wifi usb-ethernet depthai_gate robothub-agent robothub-tunnel deviceservice charger-rae lcd-show event-watch model-encrypt node-flashless-autoenable mender-commit secure-wdtclient watchdog tee-supplicant dlt docker iptables; do
  systemctl show "$unit.service" -p Id -p ActiveState -p SubState -p UnitFileState -p ExecStart
done
cat /usr/bin/lcd-show.sh
""",
    "gate": """
curl --fail --silent --show-error --max-time 5 http://127.0.0.1:11492/api/v1/version
rpm -qa | sort | sed -n '/depthai/p'
find /usr/lib/python3.8/site-packages/depthai_gate -maxdepth 3 -name '*.py' -exec grep -nE 'add_resource|route\\(' {} +
find /tmp -maxdepth 4 -name depthai-device-kb -print
""",
    "robothub": """
ls -l /usr/libexec/robothub
/usr/libexec/robothub/podman --version
stat -c '%n %s bytes' /usr/libexec/robothub/app.rha
find /home/robothub -maxdepth 1 -mindepth 1 -printf '%f\\n'
findmnt -t fuse-overlayfs
ps -eo comm | grep -E 'launch|python|robothub'
free -b
ps -eo comm,rss --sort=-rss | head -n 12
""",
    "containers": """
docker version --format '{{json .Server}}'
docker info --format '{{json .DockerRootDir}} {{json .Driver}} {{json .CgroupDriver}} {{json .DefaultRuntime}} {{json .SecurityOptions}} {{json .RegistryConfig.InsecureRegistryCIDRs}}'
docker images --format '{{.Repository}}:{{.Tag}}'
docker ps -a --format '{{.Names}} {{.Status}}'
test ! -e /etc/docker/daemon.json && echo '/etc/docker/daemon.json absent'
if command -v docker-compose; then :; else echo 'docker-compose absent'; fi
if command -v podman; then :; else echo 'podman absent from PATH'; fi
""",
    "software": """
python3 --version
python3 -c 'import importlib.util, importlib.metadata as m; print("numpy", m.version("numpy")); print("Flask", m.version("Flask")); print("Flask-RESTful", m.version("Flask-RESTful")); print("depthai", importlib.util.find_spec("depthai"))'
rpm -qa | sort | sed -n '/opencv/p; /openvino/p; /hddl/p; /codec/p; /^gstreamer1.0-[0-9]/p'
find /opt/openvino -maxdepth 3 -iname '*version*' -type f -print
ls -d /opt/openvino* /opt/intel/hddlunite /opt/intel/codec-unify /usr/lib/python3.8/site-packages
rpm -qa | wc -l
dnf --version
if [ -d /etc/yum.repos.d ]; then ls /etc/yum.repos.d; else echo '/etc/yum.repos.d absent'; fi
dpkg -l
for tool in gdb make python3-config vim nano screen less file rsync curl wget scp iw wpa_cli hostapd v4l2-ctl i2cdetect gpioinfo fw_printenv iptables mosquitto git gcc cmake pip3 node ros2 colcon tmux htop strace tcpdump perf gdbserver nmcli lsusb ldd nft gst-launch-1.0; do
  if command -v "$tool"; then :; else echo "$tool absent"; fi
done
""",
    "kernel": """
zcat /proc/config.gz | grep -E '^(# )?CONFIG_(PREEMPT|CGROUPS|MEMCG|NAMESPACES|USER_NS|SECCOMP|OVERLAY_FS|SQUASHFS|EXT4_FS|TUN|VETH|KVM|DM_VERITY|SECURITY_APPARMOR|USB_XHCI_HCD|USB_DWC3_DUAL_ROLE|USB_SERIAL|IKCONFIG_PROC|BRIDGE|CAN|BT|BTRFS_FS|FUSE_FS|WIREGUARD|USB_ACM|HZ)(=| )'
lsmod
cat /sys/module/apparmor/parameters/enabled
aa-status
""",
    "logging": """
cat /etc/systemd/journald.conf
test ! -d /var/log/journal && echo '/var/log/journal absent'
grep -nE 'persistent-log|^[^#].*(syslog|kern)' /etc/rsyslog.conf
systemctl show dlt.service -p ExecStart -p ActiveState
""",
}

UNIT = {
    "serial": "tr -d '\\000' < /sys/firmware/devicetree/base/serial-number; printf '\\n'; fw_printenv 'serial#'",
    "wifi_mac": "cat /sys/class/net/wlp1s0/address",
    "ap_ssid": "iw dev wlp1s0 info",
    "battery": "cat /sys/class/power_supply/bq27441-0/charge_full /sys/class/power_supply/bq27441-0/charge_full_design",
    "boot": "cat /proc/cmdline; fw_printenv mender_boot_part; findmnt -no SOURCE /",
}


def run_command(command):
    """Preserve partial output if a probe times out; keep the other probes running."""
    try:
        proc = subprocess.run(
            ["/bin/sh", "-c", command], stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, encoding="utf-8", errors="replace", timeout=30,
        )
        return {"command": command, "returncode": proc.returncode,
                "stdout": proc.stdout.replace("\u0000", "\\0"), "stderr": proc.stderr}
    except subprocess.TimeoutExpired as error:
        def decoded(value):
            if isinstance(value, bytes):
                value = value.decode("utf-8", errors="replace")
            return (value or "").replace("\u0000", "\\0")
        return {"command": command, "error": "timeout after 30 seconds",
                "stdout": decoded(error.stdout), "stderr": decoded(error.stderr)}


def collect(section):
    probes = COMMON if section == "common" else UNIT
    result = {"section": section, "probes": {}}
    for name, command in probes.items():
        result["probes"][name] = run_command(command.strip())
    return result


def controller_command(argv):
    try:
        proc = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              encoding="utf-8", errors="replace", timeout=5)
        return {"command": " ".join(argv), "returncode": proc.returncode,
                "stdout": proc.stdout, "stderr": proc.stderr}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": " ".join(argv), "error": str(error)}


def annotate(result, unit, address):
    if not isinstance(result, dict) or result.get("section") not in ("common", "unit") or not isinstance(result.get("probes"), dict):
        raise ValueError("expected a common or unit collector snapshot")
    result.update(unit=unit, ssh_target=address,
                  collected_at_utc=datetime.now(timezone.utc).isoformat(),
                  timestamp_source="controller, after collection; robot clock may be unsynchronized")
    if result["section"] == "unit":
        route = controller_command(["ip", "-j", "route", "get", address])
        link = {"route": route}
        if route.get("returncode") == 0:
            interface = json.loads(route["stdout"])[0]["dev"]
            link["address"] = controller_command(["ip", "-j", "-4", "address", "show", "dev", interface])
            driver = Path("/sys/class/net") / interface / "device/driver"
            link.update(driver_path=str(driver), driver=driver.resolve().name if driver.is_symlink() else None)
        result["controller_link"] = link
    return result


def write_result(result, output):
    content = json.dumps(result, indent=2) + "\n"
    if output is None:
        sys.stdout.write(content)
        return
    # Replace only after successful collection/validation; never truncate a snapshot on SSH failure.
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=output.parent,
                                         prefix="." + output.name, delete=False) as stream:
            temporary = stream.name
            stream.write(content)
        os.replace(temporary, output)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("section", choices=("common", "unit", "annotate"))
    parser.add_argument("--host", type=ipaddress.ip_address, help="collect over passwordless factory SSH")
    parser.add_argument("--target", type=ipaddress.ip_address, help="SSH target for annotate; no SSH connection is made")
    parser.add_argument("--unit-label", choices=("rae-alpha", "rae-beta"), help="physical unit selected by the operator")
    parser.add_argument("--output", type=Path, help="atomically save JSON instead of printing it")
    args = parser.parse_args()
    if args.section == "annotate":
        if args.host or not args.target or not args.unit_label:
            parser.error("annotate requires --target and --unit-label, without --host")
        result = annotate(json.load(sys.stdin), args.unit_label, str(args.target))
    elif args.host:
        if args.target or not args.unit_label:
            parser.error("--host requires --unit-label, without --target")
        ssh = [
            "ssh", "-F", "/dev/null", "-o", "UserKnownHostsFile=/dev/null",
            "-o", "GlobalKnownHostsFile=/dev/null", "-o", "StrictHostKeyChecking=no",
            "-o", "PubkeyAuthentication=no", "-o", "PasswordAuthentication=no",
            "-o", "KbdInteractiveAuthentication=no", "-o", "IdentityAgent=none",
            "-o", "BatchMode=yes", "-o", "ConnectTimeout=5",
            "root@" + str(args.host), "python3 - " + args.section,
        ]
        proc = subprocess.run(ssh, input=Path(__file__).read_text(), stdout=subprocess.PIPE,
                              encoding="utf-8", errors="replace")
        if proc.returncode:
            sys.exit(proc.returncode)
        result = annotate(json.loads(proc.stdout), args.unit_label, str(args.host))
    else:
        if args.unit_label or args.target:
            parser.error("local RAE collection has no controller metadata; use annotate on the computer")
        result = collect(args.section)
    write_result(result, args.output)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        sys.exit(str(error))
