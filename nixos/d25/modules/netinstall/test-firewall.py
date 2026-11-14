"""Test a built launcher's firewall helper with real UDP packets.

Run separately for each built backend, without changing the host firewall:
  python3 test-firewall.py LAUNCHER
"""

import os
import pathlib
import re
import socket
import subprocess
import sys


def run(*args, check=True):
    return subprocess.run(args, check=check, text=True)


def packet_delivered(port):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as receiver:
        receiver.bind(('127.0.0.1', port))
        receiver.settimeout(0.15)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
            sender.sendto(b'netinstall-test', ('127.0.0.1', port))
        try:
            return receiver.recv(100) == b'netinstall-test'
        except TimeoutError:
            return False


original_namespace = os.readlink('/proc/self/ns/net')
if len(sys.argv) == 2:
    os.execvp('unshare', [
        'unshare', '--user', '--map-root-user', '--net',
        sys.executable, __file__, sys.argv[1], original_namespace,
    ])
if len(sys.argv) != 3 or sys.argv[2] == original_namespace:
    sys.exit('Refusing to run without a new network namespace.')

subprocess.run(['ip', 'link', 'set', 'lo', 'up'], check=True)

launcher = pathlib.Path(sys.argv[1]).read_text()
helper = re.search(r'ExecStartPre=(\S+) open', launcher)[1]
script = pathlib.Path(helper).read_text()
paths = re.search(r'export PATH="([^$]+)', script)[1].rstrip(':').split(':')
if 'nft add rule' in script:
    nft = next(str(pathlib.Path(p) / 'nft') for p in paths if (pathlib.Path(p) / 'nft').exists())
    rules = '''add table inet nixos-fw
add chain inet nixos-fw input { type filter hook input priority filter; policy drop; }
add chain inet nixos-fw input-allow
add rule inet nixos-fw input jump input-allow
add rule inet nixos-fw input-allow udp dport 6000 accept comment "unrelated"
'''
    subprocess.run([nft, '-f', '-'], input=rules, text=True, check=True)
    reset = [nft, 'delete', 'table', 'inet', 'nixos-fw']
else:
    iptables = str(pathlib.Path(paths[0]) / 'iptables')
    for args in [('-N', 'nixos-fw'), ('-N', 'nixos-fw-accept'),
                 ('-A', 'nixos-fw-accept', '-j', 'ACCEPT'),
                 ('-A', 'INPUT', '-j', 'nixos-fw'), ('-P', 'INPUT', 'DROP'),
                 ('-A', 'nixos-fw', '-p', 'udp', '--dport', '6000', '-j', 'ACCEPT')]:
        run(iptables, *args)
    reset = [iptables, '-F', 'nixos-fw']

ports = (67, 69, 5000)
assert all(not packet_delivered(p) for p in ports)
assert packet_delivered(6000)
run(helper, 'open', 'netinstall-test-a.service')
assert all(packet_delivered(p) for p in ports)
run(helper, 'open', 'netinstall-test-b.service')
run(helper, 'close', 'netinstall-test-a.service')
assert all(packet_delivered(p) for p in ports)
run(helper, 'close', 'netinstall-test-a.service')
assert all(packet_delivered(p) for p in ports)
run(helper, 'close', 'netinstall-test-b.service')
assert all(not packet_delivered(p) for p in ports)
assert packet_delivered(6000)
run(helper, 'open', 'netinstall-test-c.service')
run(*reset)
run(helper, 'close', 'netinstall-test-c.service')
print('PASS: UDP delivery, concurrent ownership, idempotent cleanup, unrelated rule preservation, firewall reset')
