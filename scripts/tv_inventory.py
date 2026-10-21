"""Read-only, explicit-device ADB inventory. Never stores full dumps or identifiers."""
import argparse
import datetime
import json
import pathlib
import re
import subprocess


def requested_permissions(body):
    section = re.search(r'^    requested permissions:\s*\n(.*?)(?=^    \S|\Z)', body, re.M | re.S)
    if not section:
        return None
    return sorted(set(re.findall(r'^ {6,}([A-Za-z][\w.]+)\s*$', section.group(1), re.M)))


def capture(adb, serial):
    def shell(*args):
        return subprocess.run([adb, '-s', serial, 'shell', *args], check=True,
                              capture_output=True, text=True, encoding='utf-8',
                              errors='replace', timeout=90).stdout.strip()

    if shell('am', 'get-current-user') != '0':
        raise ValueError('Only owner user 0 is supported')
    props = dict(re.findall(r'^\[([^\]]+)\]: \[(.*)\]$', shell('getprop'), re.M))
    fields = {'manufacturer': 'ro.product.manufacturer', 'model': 'ro.product.model',
              'device': 'ro.product.device', 'fingerprint': 'ro.build.fingerprint',
              'firmware': 'ro.build.display.id', 'android': 'ro.build.version.release',
              'sdk': 'ro.build.version.sdk', 'abis': 'ro.product.cpu.abilist'}
    identity = {k: props.get(v, '') for k, v in fields.items()}
    packages = set(re.findall(r'^package:([\w.]+)$', shell('pm', 'list', 'packages', '--user', '0'), re.M))
    dump = shell('dumpsys', 'package', 'packages')
    blocks = re.split(r'^  Package \[([^\]]+)\].*$', dump, flags=re.M)
    metadata = {}
    for i in range(1, len(blocks), 2):
        name, body = blocks[i:i+2]
        if name not in packages:
            continue
        def value(pattern):
            match = re.search(pattern, body, re.M)
            return match.group(1).strip() if match else None
        state = value(r'^    User 0:.*? enabled=(\d+)')
        metadata[name] = {'package': name, 'versionName': value(r'^    versionName=(.*)$'),
                          'versionCode': value(r'^    versionCode=(\d+)'),
                          'targetSdk': value(r'^    versionCode=.*?targetSdk=(\d+)'),
                          'appId': value(r'^    (?:userId|appId)=(\d+)'),
                          'requestedPermissions': requested_permissions(body),
                          'system': bool(re.search(r'^    (?:pkgFlags|flags)=\[.*\bSYSTEM\b', body, re.M)),
                          'enabledSetting': int(state) if state is not None else None}
    if set(metadata) != packages or any(p['enabledSetting'] is None for p in metadata.values()):
        raise ValueError('Incomplete package metadata; nothing archived')
    launcher = 'io.github.kirillshchetinnikov.cutelauncher'
    if launcher in metadata:
        metadata[launcher]['requestedPermissions'] = requested_permissions(shell('dumpsys', 'package', launcher))
    features = set(re.findall(r'^feature:([^=\s]+)', shell('pm', 'list', 'features'), re.M))
    meminfo = shell('dumpsys', 'meminfo', launcher)
    memory = re.search(r'^\s*TOTAL PSS:\s*(\d+)', meminfo, re.M)
    if not memory:
        memory = re.search(r'^\s*TOTAL\s+(\d+)\s+', meminfo, re.M)
    diagnostics = {
        'currentHome': shell('cmd', 'package', 'resolve-activity', '--brief', '--user', '0',
                             '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME').splitlines()[-1],
        'packageCount': len(packages),
        'disabledCount': sum(p['enabledSetting'] in (2, 3, 4) for p in metadata.values()),
        'launcher': next((p for p in metadata.values() if p['package'] == launcher), None),
        'androidTvFeature': 'android.software.leanback' in features or 'android.hardware.type.television' in features,
        'launcherPssKiB': int(memory.group(1)) if memory else None,
        'accessibilityEnabled': launcher in shell('settings', 'get', 'secure', 'enabled_accessibility_services'),
        'notificationListenerEnabled': launcher in shell('settings', 'get', 'secure', 'enabled_notification_listeners'),
        'limits': ['ADB shell observations, not application-UID diagnostics',
                   'No hardware, playback, input, sleep or disable/restore tests performed']}
    return {'schemaVersion': 1, 'reportType': 'tvApplicationInventory', 'scope': 'adbReadOnlyInventory',
            'capturedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'identity': identity, 'diagnostics': diagnostics,
            'packages': [metadata[k] for k in sorted(metadata)]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', required=True)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    report = capture(args.adb, args.serial)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x', encoding='utf-8') as output:
        json.dump(report, output, ensure_ascii=False, indent=2)
        output.write('\n')
    print(f"{report['identity']['device']}: {len(report['packages'])} packages archived")
