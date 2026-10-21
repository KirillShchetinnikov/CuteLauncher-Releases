"""Read-only D-pad smoke checks. Always specify the device and package explicitly.

Uses only Python's standard library and Android SDK adb. Does not change HOME,
permissions, settings, or app data. Screens and logs stay in the chosen output.
"""
import argparse
import json
import pathlib
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--adb', required=True)
parser.add_argument('--device', required=True)
parser.add_argument('--package', required=True)
parser.add_argument('--output', required=True)
args = None
output = None

def configure(options):
    global args, output
    args = options
    output = pathlib.Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
root = pathlib.Path(__file__).resolve().parent.parent
translations = [json.loads((root / f'lib/l10n/app_{lang}.arb').read_text(encoding='utf-8')) for lang in ('ru', 'en')]

def adb(*command, binary=False):
    result = subprocess.run([args.adb, '-s', args.device, *command], capture_output=True, timeout=45)
    if result.returncode:
        raise RuntimeError((result.stderr + result.stdout).decode(errors='replace'))
    return result.stdout if binary else result.stdout.decode(errors='replace')

def keys(*values):
    adb('shell', 'input', 'keyevent', *(str(v) for v in values))
    time.sleep(.35)

def screen(name):
    for attempt in range(3):
        try:
            adb('shell', 'rm', '-f', '/sdcard/cutelauncher-acceptance.xml')
            adb('shell', 'uiautomator', 'dump', '/sdcard/cutelauncher-acceptance.xml')
            data = adb('exec-out', 'cat', '/sdcard/cutelauncher-acceptance.xml')
            ET.fromstring(data)
            break
        except Exception:
            if attempt == 2:
                raise
            time.sleep(1)
    (output / f'{name}.xml').write_text(data, encoding='utf-8')
    nodes = ET.fromstring(data).iter('node')
    return '\n'.join((n.get('text', '') + ' ' + n.get('content-desc', '')).strip() for n in nodes)

def expect(text, key):
    if not any(t[key] in text for t in translations):
        raise AssertionError(f'Missing screen label {key}')

def home():
    adb('shell', 'am', 'start', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME', '-n', args.package + '/com.leanbitlab.ltvL.MainActivity')
    time.sleep(.6)

def settings():
    home()
    keys(19, 19, 19, 21, 21, 21, 23)
    expect(screen('settings'), 'homeScreen')

# Indices are the existing production menu order. Enter each page with D-pad.
pages = [
    ('home-screen', [(0, 'homeScreen')]),
    ('sections', [(0, 'homeScreen'), (0, 'launcherSections')]),
    ('continue-watching', [(0, 'homeScreen'), (1, 'continueWatching')]),
    ('top-panel', [(0, 'homeScreen'), (2, 'topPanel')]),
    ('appearance', [(1, 'appearanceSettings')]),
    ('wallpaper', [(1, 'appearanceSettings'), (0, 'wallpaper')]),
    ('accent', [(1, 'appearanceSettings'), (1, 'accentColor')]),
    ('themes', [(1, 'appearanceSettings'), (2, 'tileStyle')]),
    ('tiles', [(1, 'appearanceSettings'), (3, 'tilesAndLabels')]),
    ('highlight', [(1, 'appearanceSettings'), (4, 'highlightAndAnimation')]),
    ('display', [(3, 'displayAndScreensaver')]),
    ('night', [(3, 'displayAndScreensaver'), (0, 'nightModeTitle')]),
    ('brightness', [(3, 'displayAndScreensaver'), (1, 'brightnessScheduler')]),
    ('clock', [(3, 'displayAndScreensaver'), (2, 'screensaverClockStyle')]),
    ('notifications', [(4, 'notifications')]),
    ('control', [(5, 'controlAndStartup')]),
    ('general', [(6, 'generalSettings')]),
    ('language', [(6, 'generalSettings'), (0, 'appLanguage')]),
    ('updates', [(6, 'generalSettings'), (1, 'appUpdates')]),
    ('backup', [(6, 'generalSettings'), (2, 'backupAndRestore')]),
    ('advanced', [(6, 'generalSettings'), (3, 'advancedSettings')]),
    ('memory', [(6, 'generalSettings'), (3, 'advancedSettings'), (0, 'memoryTitle')]),
    ('adb', [(6, 'generalSettings'), (3, 'advancedSettings'), (1, 'adbTitle')]),
    ('diagnostics', [(6, 'generalSettings'), (3, 'advancedSettings'), (2, 'diagnosticsTitle')]),
]
def run_checks():
    results = []
    try:
        for name, path in pages:
            try:
                settings()
                for index, key in path:
                    if index:
                        keys(*([20] * index))
                    keys(23)
                    expect(screen(name), key)
                (output / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p', binary=True))
                keys(4)
                expect(screen(name + '-back'), path[-2][1] if len(path) > 1 else 'settings')
                home()
                text = screen(name + '-home')
                if any(t['generalSettings'] in text for t in translations):
                    raise AssertionError('HOME retained settings route')
                results.append({'page': name, 'result': 'PASS'})
            except Exception as error:
                results.append({'page': name, 'result': 'FAIL', 'error': str(error)})
            print(json.dumps(results[-1], ensure_ascii=False), flush=True)
    finally:
        home()
        (output / 'results.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
        adb('shell', 'rm', '/sdcard/cutelauncher-acceptance.xml')
    return all(r['result'] == 'PASS' for r in results)

if __name__ == '__main__':
    configure(parser.parse_args())
    raise SystemExit(0 if run_checks() else 1)
