"""Measure the production launcher on an explicitly selected, authorized TV.

No data clearing, HOME/accessibility changes or power-profile changes. Installs
only when --apk is supplied. Logs and measurements stay in the selected folder.
"""
import argparse
import json
import re
import subprocess
import time
from pathlib import Path

PACKAGE = 'io.github.kirillshchetinnikov.cutelauncher'
COMPONENT = PACKAGE + '/com.leanbitlab.ltvL.MainActivity'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--adb', required=True)
    parser.add_argument('--device', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--runs', type=int, default=3)
    parser.add_argument('--sleep-seconds', type=int, default=4)
    args = parser.parse_args()
    if args.device != '192.168.1.73:5555':
        parser.error('This hardware measurement is authorized for TCL .73 only')
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command, timeout=45):
        return subprocess.run([args.adb, '-s', args.device, *command],
                              check=True, capture_output=True, text=True,
                              encoding='utf-8', errors='replace', timeout=timeout).stdout

    if args.apk:
        adb('install', '-r', str(args.apk.resolve()), timeout=180)
    offsets = []
    for _ in range(5):
        before = time.time()
        device_time = float(adb('shell', 'date', '+%s.%N').strip())
        after = time.time()
        offsets.append((after - before, device_time - (before + after) / 2))
    uncertainty, clock_offset = min(offsets)
    def timestamp():
        return time.time() + clock_offset
    log_path = args.output / 'logcat.txt'
    report = {'device': args.device, 'clockOffsetSeconds': clock_offset,
              'clockUncertaintyMs': round(uncertainty * 500, 1), 'samples': []}
    with log_path.open('w', encoding='utf-8') as stream:
        logger = subprocess.Popen([args.adb, '-s', args.device, 'logcat', '-v', 'epoch', '-T', '1'],
                                  stdout=stream, stderr=subprocess.STDOUT)
        try:
            def events():
                result = []
                for line in log_path.read_text(encoding='utf-8', errors='replace').splitlines():
                    match = re.search(r'CUTE_STARTUP (\{.*\})', line)
                    if match:
                        try:
                            event = json.loads(match[1])
                            event['logTime'] = float(line.split()[0])
                            result.append(event)
                        except (ValueError, IndexError):
                            pass
                return result

            def wait_phase(phase, start, timeout=35):
                deadline = time.monotonic() + timeout
                while time.monotonic() < deadline:
                    matches = [e for e in events() if e['phase'] == phase and e['logTime'] >= start]
                    if matches:
                        return matches[0]
                    time.sleep(.1)
                raise RuntimeError(f'No {phase} after scenario start')

            def launch():
                return adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN',
                           '-c', 'android.intent.category.HOME', '-n', COMPONENT)

            def keys(sample):
                values = []
                for key in ('22', '21', '22', '21'):
                    start = timestamp()
                    adb('shell', 'input', 'keyevent', key)
                    event = wait_phase('keyFrame', start, timeout=12)
                    values.append({'hostToFrameMs': round((event['logTime'] - start) * 1000, 1),
                                   'dartToFrameMs': round(event['latencyUs'] / 1000, 1),
                                   'focus': event.get('focus')})
                    time.sleep(.2)
                sample['keys'] = values
                focused = [value['focus'] for value in values if value['focus'] is not None]
                if len(focused) == len(values) and len(set(focused)) < 2:
                    raise RuntimeError('Remote input produced frames but did not move app focus')

            adb('shell', 'input', 'keyevent', '224')
            for index in range(args.runs):
                start = timestamp()
                adb('shell', 'am', 'force-stop', PACKAGE)
                launch_output = launch()
                ready = wait_phase('homeReady', start)
                sample = {'scenario': 'cold', 'run': index,
                          'hostToReadyMs': round((ready['logTime'] - start) * 1000, 1),
                          'dartToReadyMs': round(ready['elapsedUs'] / 1000, 1),
                          'amStart': launch_output.strip()}
                keys(sample)
                report['samples'].append(sample)
                time.sleep(3)
                adb('shell', 'am', 'start', '-a', 'android.settings.SETTINGS')
                time.sleep(2)
                start = timestamp()
                launch()
                ready = wait_phase('resumeFrame', start)
                sample = {'scenario': 'return', 'run': index,
                          'hostToFrameMs': round((ready['logTime'] - start) * 1000, 1)}
                keys(sample)
                report['samples'].append(sample)
                time.sleep(3)
                adb('shell', 'input', 'keyevent', '223')
                time.sleep(args.sleep_seconds)
                asleep = adb('shell', 'dumpsys', 'power')
                if not re.search(r'mWakefulness=(Asleep|Dozing)', asleep):
                    raise RuntimeError('TV did not enter sleep')
                start = timestamp()
                adb('shell', 'input', 'keyevent', '224')
                ready = wait_phase('resumeFrame', start)
                sample = {'scenario': 'wake', 'run': index,
                          'hostToFrameMs': round((ready['logTime'] - start) * 1000, 1)}
                keys(sample)
                report['samples'].append(sample)
                time.sleep(3)
                (args.output / 'measurements.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        finally:
            logger.terminate()
            logger.wait(timeout=10)
            (args.output / 'measurements.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
