"""Check two cold starts of a normal release on a named TV emulator, preserving app data."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

PACKAGE = 'io.github.kirillshchetinnikov.cutelauncher'
AVDS = {'TV_Android_TV', 'TV_Google_TV'}
ERRORS = re.compile(
    r'FATAL EXCEPTION|UnsatisfiedLinkError|MissingPluginException|'
    r'Error registering plugin|Unhandled Exception|No implementation found for method')


def check(adb, device, avd, apk):
    def run(*args, timeout=45):
        return subprocess.run([str(adb), '-s', device, *map(str, args)],
                              capture_output=True, encoding='utf-8', errors='replace',
                              check=True, timeout=timeout).stdout.strip()

    if avd not in AVDS or not device.startswith('emulator-'):
        raise ValueError('Only the named TV emulators are supported')
    if run('emu', 'avd', 'name').splitlines()[0] != avd:
        raise ValueError('Unexpected AVD for this device')
    if run('shell', 'getprop', 'ro.product.cpu.abi') != 'x86_64':
        raise ValueError('An x86_64 TV emulator is required')
    if run('shell', 'getprop', 'sys.boot_completed') != '1':
        raise ValueError('Emulator has not finished booting')
    packages = run('shell', 'pm', 'list', 'packages', PACKAGE).splitlines()
    if any(line != 'package:' + PACKAGE for line in packages):
        raise ValueError('Remove duplicate debug/profile launcher packages first')
    if 'Success' not in run('install', '-r', apk, timeout=120):
        raise AssertionError('Release APK installation failed')
    results = []
    for attempt in range(2):
        run('shell', 'am', 'force-stop', PACKAGE)
        launched = run('shell', 'am', 'start', '-W', '-n',
                       PACKAGE + '/com.leanbitlab.ltvL.MainActivity')
        if 'Status: ok' not in launched:
            raise AssertionError('Activity launch failed: ' + launched)
        deadline = time.monotonic() + 45
        labels = set()
        while time.monotonic() < deadline:
            run('shell', 'uiautomator', 'dump', '/data/local/tmp/cutelauncher-size.xml')
            root = ET.fromstring(run('shell', 'cat', '/data/local/tmp/cutelauncher-size.xml'))
            labels = {node.get('text') or node.get('content-desc') for node in root.iter('node')
                      if node.get('package') == PACKAGE
                      and (node.get('text') or node.get('content-desc'))}
            if len(labels) >= 3:
                break
            time.sleep(1)
        if len(labels) < 3:
            raise AssertionError('Flutter did not expose a populated application screen')
        pid = run('shell', 'pidof', PACKAGE)
        if not pid or not pid.isdigit():
            raise AssertionError('Launcher process is not alive')
        log = run('logcat', '-d', '--pid=' + pid, '-v', 'brief')
        errors = [line for line in log.splitlines() if ERRORS.search(line)]
        if errors:
            raise AssertionError('\n'.join(errors))
        results.append({'cold_start': attempt + 1, 'visible_labels': len(labels),
                        'process_alive': True, 'runtime_errors': 0})
    run('shell', 'rm', '-f', '/data/local/tmp/cutelauncher-size.xml')
    return {'avd': avd, 'apk': str(apk), 'result': 'PASS', 'checks': results}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', type=Path, required=True)
    parser.add_argument('--device', required=True)
    parser.add_argument('--avd', choices=sorted(AVDS), required=True)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = check(args.adb, args.device, args.avd, args.apk)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False))
