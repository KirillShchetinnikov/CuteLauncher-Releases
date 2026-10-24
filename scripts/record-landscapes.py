"""Record the local capture target on an explicitly selected TV emulator.

Build lib/diagnostics/landscape_capture_main.dart in debug/profile first.
The normal launcher does not import that target. Requires no Python packages.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', required=True)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--avd', required=True, choices=['TV_Android_TV', 'TV_Google_TV'])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--package', default='io.github.kirillshchetinnikov.cutelauncher.debug')
    parser.add_argument('--languages', nargs='+', choices=['ru', 'en'], default=['ru', 'en'])
    args = parser.parse_args()
    args.languages = list(dict.fromkeys(args.languages))

    def adb(*parts):
        return subprocess.check_output(
            [args.adb, '-s', args.serial, *parts], text=True, encoding='utf-8',
        ).strip()

    if not args.serial.startswith('emulator-'):
        parser.error('Capture is restricted to TV emulators; physical TVs are not used.')
    if adb('emu', 'avd', 'name').splitlines()[0].strip() != args.avd:
        parser.error('The connected AVD does not match --avd.')
    args.output.mkdir(parents=True, exist_ok=True)
    outputs = [args.output / f'CuteLauncher-landscape-{v}-{lang}-1080p.mp4'
               for lang in args.languages for v in ['illustrated', 'realistic']]
    manifest = args.output / 'capture.json'
    if any(p.exists() for p in [*outputs, manifest]):
        parser.error('Output files already exist; choose a new directory.')

    def override(kind):
        state = adb('shell', 'wm', kind)
        match = re.search(r'Override (?:size|density):\s*(\S+)', state)
        return match.group(1) if match else 'reset'

    size, density = override('size'), override('density')
    recorder = None
    remote = f'/sdcard/cutelauncher-landscape-{uuid.uuid4().hex}.mp4'
    results = []
    try:
        adb('shell', 'wm', 'size', '1920x1080')
        adb('shell', 'wm', 'density', '320')
        adb('shell', 'am', 'force-stop', args.package)
        adb('shell', 'am', 'start', '-W', '-n',
            f'{args.package}/com.leanbitlab.ltvL.MainActivity')
        deadline = time.monotonic() + 45
        pid = ''
        while time.monotonic() < deadline:
            pid = adb('shell', 'pidof', args.package)
            if pid and 'LANDSCAPE_CAPTURE ready' in adb(
                'logcat', '-d', '--pid', pid, '-s', 'flutter:I', '*:S',
            ):
                break
            time.sleep(.5)
        else:
            raise RuntimeError('The debug/profile capture target did not become ready.')
        for language in args.languages:
            adb('shell', 'input', 'keyevent', '10' if language == 'ru' else '11')  # 3/4
            time.sleep(.5)
            log = adb('logcat', '-d', '--pid', pid, '-s', 'flutter:I', '*:S')
            if f'LANDSCAPE_CAPTURE language {language}' not in log:
                raise RuntimeError(f'The target did not switch to {language}.')
            for key, variant in [('8', 'illustrated'), ('9', 'realistic')]:
                output = args.output / f'CuteLauncher-landscape-{variant}-{language}-1080p.mp4'
                adb('shell', 'input', 'keyevent', key)  # KEYCODE_1 / KEYCODE_2
                # Let the previous season/variant transition and all decoded images settle.
                time.sleep(4)
                completed_before = adb(
                    'logcat', '-d', '--pid', pid, '-s', 'flutter:I', '*:S',
                ).count('LANDSCAPE_CAPTURE complete')
                print(f'Recording {variant} / {language}: 1920x1080, 45 seconds', flush=True)
                recorder = subprocess.Popen(
                    [args.adb, '-s', args.serial, 'shell', 'screenrecord',
                     '--size', '1920x1080', '--bit-rate', '20M', '--time-limit', '45', remote],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                )
                time.sleep(2)
                if recorder.poll() is not None:
                    raise RuntimeError(f'screenrecord exited early: {recorder.communicate()}')
                adb('shell', 'input', 'keyevent', '66')  # Enter: clean single cycle
                # Check the actual app acknowledged the selected variant and playback.
                time.sleep(.3)
                log = adb('logcat', '-d', '--pid', pid, '-s', 'flutter:I', '*:S')
                if f'LANDSCAPE_CAPTURE start {variant}' not in log:
                    raise RuntimeError(f'The capture target did not start {variant}.')
                stdout, stderr = recorder.communicate(timeout=55)
                if recorder.returncode:
                    raise RuntimeError(f'screenrecord failed: {stdout}\n{stderr}')
                log = adb('logcat', '-d', '--pid', pid, '-s', 'flutter:I', '*:S')
                if log.count('LANDSCAPE_CAPTURE complete') <= completed_before:
                    raise RuntimeError('The demo did not finish within the recording.')
                adb('pull', remote, str(output))
                adb('shell', 'rm', remote)
                results.append({'variant': variant, 'language': language, 'file': output.name,
                                'bytes': output.stat().st_size,
                                'sha256': hashlib.sha256(output.read_bytes()).hexdigest()})
                print(f'Saved {output}', flush=True)
        manifest.write_text(json.dumps({
            'avd': args.avd, 'size': [1920, 1080], 'bit_rate': 20000000,
            'caption': {'locales': args.languages, 'position': 'top-left', 'effect': True, 'time': True},
            'start': (re.search(r'LANDSCAPE_CAPTURE ready start=([^\s]+)', log).group(1)
                      if re.search(r'LANDSCAPE_CAPTURE ready start=([^\s]+)', log) else None),
            'initial_season': 'summer', 'initial_time': '12:00',
            'sun_times': 'device cache with shared fallback', 'files': results,
        }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    finally:
        if recorder is not None and recorder.poll() is None:
            adb('shell', 'pkill', '-INT', 'screenrecord')
            recorder.communicate(timeout=15)
        adb('shell', 'wm', 'size', size)
        adb('shell', 'wm', 'density', density)


if __name__ == '__main__':
    main()
