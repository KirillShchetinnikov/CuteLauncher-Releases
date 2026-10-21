"""Controlled release probe. Explicit device, isolated fixtures, timer rollback.

Baseline: two profiles x two modes + saturated heavy profile x two modes.
Compare: fresh processes in normal/economy/economy/normal order.
Long: four 30-minute phases of the selected configuration.
"""
import argparse
import csv
import datetime
import hashlib
import importlib.util
import json
import pathlib
import re
import subprocess
import sys
import time
import types
import xml.etree.ElementTree as ET

PACKAGE = 'io.github.kirillshchetinnikov.cutelauncher'
ACTIVITY = PACKAGE + '/com.leanbitlab.ltvL.MainActivity'
CONFIG = '/sdcard/Android/data/' + PACKAGE + '/files/economy-probe.json'
TIMERS = [('system', 'screen_off_timeout'), ('secure', 'sleep_timeout'), ('secure', 'attentive_timeout')]
parser = argparse.ArgumentParser()
parser.add_argument('--adb', required=True)
parser.add_argument('--device', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--apk')
parser.add_argument('--suite', choices=['baseline', 'matrix', 'short', 'compare', 'long', 'emulator', 'launcher', 'launcher-short', 'overhead', 'overhead-short', 'pressure', 'small'], default='emulator')
parser.add_argument('--watch', action='store_true')
parser.add_argument('--restore', action='store_true')
parser.add_argument('--start-run', type=int, default=0)
args = parser.parse_args()
out = pathlib.Path(args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
is_tv = args.device == '192.168.1.73:5555'
STOCK_HOME = 'com.omeda.arc/.MainActivity' if is_tv else 'com.google.android.tvlauncher/.MainActivity'
if not is_tv and not args.device.startswith('emulator-'):
    raise RuntimeError('Only the authorized TCL43 or a local emulator is allowed')

def adb(*command):
    command = list(map(str, command))
    read_only = command[:2] in [['shell', 'dumpsys'], ['shell', 'getprop'], ['shell', 'pidof']] or command[:3] == ['shell', 'settings', 'get']
    for attempt in range(3 if read_only else 1):
        result = subprocess.run([args.adb, '-s', args.device, *command], capture_output=True, text=True, timeout=60)
        if not result.returncode:
            return result.stdout.strip()
        if result.returncode == 1 and command[:2] == ['shell', 'pidof'] and not (result.stdout.strip() or result.stderr.strip()):
            return ''
        if read_only and attempt < 2:
            time.sleep(1)
    raise RuntimeError(f'ADB exit {result.returncode}: {" ".join(command)}: {result.stderr or result.stdout or "empty output"}')

def save(name, data):
    (out / name).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')

def restore():
    data = json.loads((out / 'timers.json').read_text(encoding='utf-8'))
    for ns, key, value in data['values']:
        if (ns, key) not in TIMERS or (value != 'null' and not value.isdigit()):
            raise RuntimeError('Invalid timer backup')
        adb('shell', 'settings', 'delete' if value == 'null' else 'put', ns, key, *([] if value == 'null' else [value]))
        if adb('shell', 'settings', 'get', ns, key) != value:
            raise RuntimeError('Timer rollback failed: ' + key)
    save('timers-restored.json', {'values': data['values'], 'time': time.time()})

_ui_module = None
def ui():
    global _ui_module
    if _ui_module is None:
        spec = importlib.util.spec_from_file_location('device_ui', pathlib.Path(__file__).with_name('device-ui-check.py'))
        _ui_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(_ui_module)
        _ui_module.configure(types.SimpleNamespace(adb=args.adb, device=args.device, package=PACKAGE, output=str(out / 'ui-precheck')))
    return _ui_module

def open_setting(key):
    helper = ui()
    labels = [item[key] for item in helper.translations]
    for attempt in range(16):
        helper.screen('focus-' + key)
        nodes = list(ET.parse(out / ('ui-precheck/focus-' + key + '.xml')).getroot().iter('node'))
        if any(node.get('focused') == 'true' and
               (node.get('content-desc') in labels or node.get('text') in labels)
               for node in nodes):
            helper.keys(23)
            helper.expect(helper.screen('route-' + key), key)
            return
        actions = [node for node in nodes if node.get('focusable') == 'true' and
                   node.get('clickable') == 'true' and node.get('content-desc')]
        current = next((index for index, node in enumerate(actions) if node.get('focused') == 'true'), None)
        target = next((index for index, node in enumerate(actions) if node.get('content-desc') in labels), None)
        if current is not None and target is not None and current != target:
            helper.keys(*([20 if target > current else 19] * abs(target - current)))
        else:
            helper.keys(20)
    raise RuntimeError('Could not focus settings action: ' + key)

def memory_page():
    ui().settings()
    for key in ['generalSettings', 'advancedSettings', 'memoryTitle']:
        open_setting(key)

def saver_value():
    helper = ui()
    for attempt in range(8):
        helper.screen('saver-switch')
        nodes = list(ET.parse(out / 'ui-precheck/saver-switch.xml').getroot().iter('node'))
        checked = [node for node in nodes if node.get('checkable') == 'true']
        labels = [item['memorySaver'] for item in helper.translations]
        focused = any(node.get('content-desc') in labels and node.get('focused') == 'true' for node in nodes)
        if len(checked) == 1 and (focused or checked[0].get('focused') == 'true'):
            return checked[0].get('checked') == 'true'
        helper.keys(20)
    raise RuntimeError('Memory switch could not be focused')

def set_saver(value):
    memory_page()
    if saver_value() != value:
        ui().keys(23)
        if saver_value() != value:
            raise RuntimeError('Memory profile change failed')
    ui().home()

def restore_saver():
    backup = out / 'saver-original.json'
    if backup.exists():
        set_saver(json.loads(backup.read_text())['value'])
        save('saver-restored.json', {'time': time.time(), 'value': json.loads(backup.read_text())['value']})

if args.restore:
    restore_saver()
    restore()
    sys.exit()

if args.watch:
    while not (out / 'timers-restored.json').exists():
        heartbeat = out / 'heartbeat'
        if heartbeat.exists() and time.time() - heartbeat.stat().st_mtime > 180:
            break
        if time.time() - json.loads((out / 'timers.json').read_text())['time'] > 6 * 3600:
            break
        time.sleep(15)
    if not (out / 'timers-restored.json').exists():
        for attempt in range(3):
            try:
                restore()
                break
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(15)
        restore_saver()
    sys.exit()

if (out / 'memory.csv').exists():
    raise RuntimeError('Existing measurements must not be overwritten; choose a new output directory')

if is_tv and adb('shell', 'getprop', 'ro.product.model') != 'Smart TV Pro':
    raise RuntimeError('Unexpected TV model')

def heartbeat():
    (out / 'heartbeat').touch()

def configure(data):
    local = out / 'config.json'
    local.write_text(json.dumps(data), encoding='utf-8')
    adb('shell', 'mkdir', '-p', CONFIG.rsplit('/', 1)[0])
    adb('push', local, CONFIG)

def launch():
    adb('shell', 'input', 'keyevent', 224)
    adb('shell', 'am', 'force-stop', PACKAGE)
    adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME', '-n', ACTIVITY)
    time.sleep(3)
    return adb('shell', 'pidof', PACKAGE)

def require_awake():
    if is_tv:
        power = adb('shell', 'dumpsys', 'power')
        if not re.search(r'mWakefulness=Awake\b', power):
            raise RuntimeError('The TV screen is not awake; measurements are invalid')

fields = ['utc', 'run', 'phase', 'seconds', 'pid', 'pss_kib', 'rss_kib', 'graphics_kib', 'native_kib', 'java_kib']
file = (out / 'memory.csv').open('w', newline='', encoding='utf-8')
writer = csv.DictWriter(file, fieldnames=fields)
writer.writeheader()
_stream = None
_stream_file = None

def start_log(run, pid, append=False):
    global _stream, _stream_file
    _stream_file = (out / (run + '-logcat.txt')).open('a' if append else 'w', encoding='utf-8')
    _stream = subprocess.Popen([args.adb, '-s', args.device, 'logcat', '-v', 'threadtime', '--pid=' + pid],
                               stdout=_stream_file, stderr=subprocess.DEVNULL, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))

def stop_log():
    global _stream, _stream_file
    if _stream is not None:
        _stream.terminate()
        try:
            _stream.wait(timeout=5)
        except subprocess.TimeoutExpired:
            _stream.kill()
            _stream.wait(timeout=5)
        _stream = None
    if _stream_file is not None:
        _stream_file.close()
        _stream_file = None

def cpu_sample(pid):
    # /proc stat fields 14/15 are process user/system ticks. Record the clock
    # frequency from this device rather than assuming the host's frequency.
    try:
        fields = adb('shell', 'cat', '/proc/' + pid + '/stat').rsplit(')', 1)[1].split()
        return {'time': time.monotonic(), 'pid': pid,
                'ticks': int(fields[11]) + int(fields[12]),
                'hz': int(adb('shell', 'getconf', 'CLK_TCK'))}
    except (RuntimeError, ValueError, IndexError) as error:
        return {'unavailable': str(error)}

def stable_background_samples(samples, begin, end):
    # Device JSON and host CSV use different clocks. Keep the return boundary
    # out of lifecycle validation; native resumed activity is checked at both
    # ends of the full background interval.
    return [sample for sample in samples
            if begin + 30 <= datetime.datetime.fromisoformat(
                sample['time'].replace('Z', '+00:00')).timestamp() <= end - 10]

def phase(run, name, seconds, pid):
    start = time.monotonic()
    background = name.startswith('background')
    while time.monotonic() - start < seconds + (2 if background else 0):
        heartbeat()
        require_awake()
        actual = adb('shell', 'pidof', PACKAGE)
        if actual != pid:
            if not (background and not actual):
                raise RuntimeError(f'Process changed during {run}/{name}: {pid} -> {actual}')
            report = out / (run + '-background-exit.txt')
            if not report.exists():
                report.write_text(adb('shell', 'dumpsys', 'activity', 'exit-info', PACKAGE), encoding='utf-8')
        mem = adb('shell', 'dumpsys', 'meminfo', PACKAGE) if actual else ''
        row = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'run': run,
               'phase': name, 'seconds': round(time.monotonic() - start, 1), 'pid': actual}
        for key, pattern in [('pss_kib', r'TOTAL PSS:\s*(\d+)'), ('rss_kib', r'TOTAL RSS:\s*(\d+)'),
                             ('graphics_kib', r'Graphics:\s*(\d+)'), ('native_kib', r'Native Heap:\s*(\d+)'), ('java_kib', r'Java Heap:\s*(\d+)')]:
            match = re.search(pattern, mem)
            row[key] = int(match[1]) if match else ''
        if actual and (row['pss_kib'] == '' or row['rss_kib'] == ''):
            raise RuntimeError('Missing process memory totals')
        writer.writerow(row)
        file.flush()
        if args.suite in ['launcher', 'launcher-short'] and name.startswith('load'):
            ui().home()
            ui().keys(*([22] * 8 + [21] * 8 + [20] * 4 + [19] * 4))
            ui().settings()
            open_setting('appearanceSettings')
            ui().keys(20, 20, 20, 19, 19, 19, 4)
            ui().home()
        if background:
            targets = [target for target in [5, 30, 90] if target > time.monotonic() - start]
            if not targets:
                return
            time.sleep(max(0, targets[0] - (time.monotonic() - start)))
        else:
            time.sleep(min(15, max(0, seconds - (time.monotonic() - start))))

def record_log(run, pid, saturated):
    stop_log()
    log = (out / (run + '-logcat.txt')).read_text(encoding='utf-8', errors='replace')
    samples = []
    for line in log.splitlines():
        if 'CUTE_PERF ' in line:
            sample = json.loads(line.split('CUTE_PERF ', 1)[1])
            match = re.search(r'\s(\d+)\s+\d+\s+[IVDEWF]\s+flutter\s*:', line)
            sample['pid'] = match[1] if match else None
            samples.append(sample)
    save(run + '-frames.json', samples)
    if any(marker in log for marker in ['FATAL EXCEPTION', 'EXCEPTION CAUGHT BY', 'Unhandled Exception', 'FLauncher Error Boundary:']):
        raise RuntimeError('Runtime error in ' + run)
    diagnostics = json.loads((out / 'config.json').read_text()).get('diagnostics', True)
    if diagnostics:
        if not samples or not any(sample['frames'] for sample in samples):
            raise RuntimeError('No Flutter frames measured in ' + run)
        if any(sample['overflow'] for sample in samples):
            raise RuntimeError('Frame buffer overflow in ' + run)
        if saturated and max(sample['decoded_entries'] for sample in samples) < 64:
            raise RuntimeError('Saturated fixture did not reach the reduced entry limit')
        background_rows = [row for row in csv.DictReader((out / 'memory.csv').open(encoding='utf-8'))
                           if row['run'] == run and row['phase'].startswith('background')]
        if background_rows:
            begin = datetime.datetime.fromisoformat(background_rows[0]['utc']).timestamp()
            end = datetime.datetime.fromisoformat(background_rows[-1]['utc']).timestamp()
            background_samples = stable_background_samples(samples, begin, end)
            # Android may freeze a cached process, including its diagnostic
            # timer. Absence of JSON then is not evidence of a failed lifecycle.
            if any(sample['foreground'] for sample in background_samples):
                raise RuntimeError('Background phase did not hide the Flutter view in ' + run)
    elif samples:
        raise RuntimeError('Diagnostics-off run unexpectedly contains timing samples')

try:
    if is_tv:
        save('timers.json', {'time': time.time(), 'values': [(ns, key, adb('shell', 'settings', 'get', ns, key)) for ns, key in TIMERS]})
        heartbeat()
        subprocess.Popen([sys.executable, __file__, '--adb', args.adb, '--device', args.device,
                          '--output', str(out), '--watch'], creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        for ns, key in TIMERS:
            adb('shell', 'settings', 'put', ns, key, 28800000)
    if args.apk:
        apk = pathlib.Path(args.apk).resolve()
        save('apk.json', {'path': apk.name, 'sha256': hashlib.sha256(apk.read_bytes()).hexdigest()})
        adb('install', '-r', apk)
    save('environment.json', {key: adb('shell', *command) for key, command in {
        'model': ['getprop', 'ro.product.model'], 'abi': ['getprop', 'ro.product.cpu.abi'],
        'sdk': ['getprop', 'ro.build.version.sdk'], 'resolution': ['wm', 'size'],
        'density': ['wm', 'density'], 'version': ['dumpsys', 'package', PACKAGE],
    }.items()})
    if args.suite == 'emulator':
        runs = [(True, True, True)]
        warm, load = 30, 90
    elif args.suite == 'baseline':
        runs = [(economy, heavy, saturated) for saturated, heavy in [(False, False), (False, True), (True, True)] for economy in [False, True]]
        warm, load = 120, 300
    elif args.suite == 'matrix':
        runs = [(economy, heavy, False) for heavy in [False, True] for economy in [False, True]]
        runs += [(economy, True, True) for economy in [False, True, True, False]]
        warm, load = 120, 300
    elif args.suite == 'small':
        runs = [(True, False, False)]
        warm, load = 120, 300
    elif args.suite == 'short':
        runs = [(True, True, False)] + [(economy, True, True) for economy in [False, True, True, False]]
        warm, load = 60, 180
    elif args.suite == 'compare':
        runs = [(economy, True, True) for economy in [False, True, True, False]]
        warm, load = 120, 600
    elif args.suite == 'long':
        runs = [(economy, True, True) for economy in [False, False, True, True]]
        warm, load = 120, 1800
    elif args.suite in ['overhead', 'overhead-short']:
        runs = [(False, True, False)] * (2 if args.suite == 'overhead-short' else 4)
        warm = load = 30 if args.suite == 'overhead-short' else 60
    elif args.suite == 'pressure':
        runs = [(economy, True, True) for economy in [False, True]]
        warm, load = 60, 30
    elif args.suite in ['launcher', 'launcher-short']:
        runs = [(economy, False, False) for economy in ([False, True] if args.suite == 'launcher-short' else [False, True, True, False])]
        warm, load = (45, 60) if args.suite == 'launcher-short' else (120, 180)
        configure({'scenario': 'launcher'})
        launch()
        memory_page()
        save('saver-original.json', {'value': saver_value()})
    else:
        runs = [(False, False, False)]
        warm, load = 120, 300
    for number, (economy, heavy, saturated) in enumerate(runs):
        if number < args.start_run:
            continue
        run = f'{number}-{"economy" if economy else "normal"}-{"heavy" if heavy else "everyday"}-{"saturated" if saturated else "small"}'
        configure({'economy': economy, 'heavy': heavy, 'saturated': saturated,
                   'diagnostics': number in [0, 3] if args.suite in ['overhead', 'overhead-short'] else True,
                   'scenario': 'launcher' if args.suite in ['launcher', 'launcher-short'] else 'fixture'})
        save(run + '-config.json', json.loads((out / 'config.json').read_text()))
        if args.suite in ['launcher', 'launcher-short']:
            set_saver(economy)
        adb('logcat', '-c')
        pid = launch()
        start_log(run, pid)
        print('Started ' + run + ' PID ' + pid, flush=True)
        phase(run, 'warm', warm, pid)
        if args.suite == 'pressure':
            adb('shell', 'input', 'keyevent', 66)
            phase(run, 'before_trim', 20, pid)
            result = adb('shell', 'am', 'send-trim-memory', PACKAGE, 'RUNNING_LOW')
            save(run + '-trim.json', {'pid': pid, 'result': result, 'time': time.time()})
            phase(run, 'after_trim', 30, pid)
            adb('shell', 'input', 'keyevent', 22, 21)
            phase(run, 'navigation_after_trim', 15, pid)
            record_log(run, pid, saturated)
            print('Completed ' + run, flush=True)
            continue
        if args.suite in ['overhead', 'overhead-short']:
            cpu_before = cpu_sample(pid)
            phase(run, 'load0', load, pid)
            cpu_after = cpu_sample(pid)
            save(run + '-cpu.json', {'before': cpu_before, 'after': cpu_after})
            record_log(run, pid, saturated)
            print('Completed ' + run, flush=True)
            continue
        idle_run = args.suite == 'long' and number % 2 == 0
        run_load = 600 if args.suite == 'matrix' and number >= 4 else load
        if args.suite == 'short' and number == 0:
            run_load = 120
        if idle_run:
            adb('shell', 'input', 'keyevent', 66)
        for cycle in range(1):
            phase(run, ('plateau_idle' if idle_run else 'load') + str(cycle), run_load, pid)
            if args.suite not in ['launcher', 'launcher-short']:
                if not idle_run:
                    adb('shell', 'input', 'keyevent', 66)
            phase(run, 'idle' + str(cycle), 30 if args.suite in ['short', 'launcher-short'] else 60, pid)
            if args.suite == 'short' and number not in [1, 2]:
                continue
            background_intent = adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME', '-n', STOCK_HOME)
            (out / (run + '-background-intent.txt')).write_text(background_intent)
            native_state = adb('shell', 'dumpsys', 'activity', 'activities')
            resumed = [line.strip() for line in native_state.splitlines()
                       if 'topResumedActivity=' in line or 'ResumedActivity:' in line]
            save(run + '-background-state.json', {'resumed': resumed})
            if not any(STOCK_HOME.split('/')[0] in line for line in resumed):
                raise RuntimeError('Stock Home is not the resumed background target')
            phase(run, 'background' + str(cycle), 90, pid)
            final_native_state = adb('shell', 'dumpsys', 'activity', 'activities')
            final_resumed = [line.strip() for line in final_native_state.splitlines()
                             if 'topResumedActivity=' in line or 'ResumedActivity:' in line]
            save(run + '-background-end-state.json', {'resumed': final_resumed})
            if not any(STOCK_HOME.split('/')[0] in line for line in final_resumed):
                raise RuntimeError('Stock Home did not remain resumed for the full background interval')
            returned = adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME', '-n', ACTIVITY)
            return_pid = adb('shell', 'pidof', PACKAGE)
            save(run + '-return-process.json', {'before_pid': pid, 'return_pid': return_pid, 'cold': pid != return_pid})
            if return_pid != pid:
                stop_log()
                start_log(run, return_pid, append=True)
                pid = return_pid
            (out / (run + '-return' + str(cycle) + '.txt')).write_text(returned)
            phase(run, 'return' + str(cycle), 30 if args.suite in ['short', 'launcher-short'] else 60, pid)
            if args.suite not in ['launcher', 'launcher-short']:
                adb('shell', 'input', 'keyevent', 66)
        record_log(run, pid, saturated)
        print('Completed ' + run, flush=True)
    save('complete.json', {'time': time.time(), 'runs': len(runs) - args.start_run})
except BaseException as error:
    save('failed.json', {'time': time.time(), 'error': str(error)})
    raise
finally:
    stop_log()
    file.close()
    try:
        if args.suite in ['launcher', 'launcher-short']:
            restore_saver()
    finally:
        if is_tv and (out / 'timers.json').exists():
            restore()
