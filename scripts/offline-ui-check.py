"""D-pad checks of the normal launcher with Android's per-app firewall enabled.

Use OfflineStartupProbe to back up preferences before running. This script never
enables the firewall itself or changes HOME/permissions. Always name the emulator.
"""
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location('device_ui', Path(__file__).with_name('device-ui-check.py'))
ui = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ui)

if __name__ == '__main__':
    ui.parser.add_argument('--only', default='weather,night-schedule,updates,backup', help='Comma-separated page names')
    ui.parser.add_argument('--solar-times', choices=('defaults', 'history'))
    options = ui.parser.parse_args()
    ui.configure(options)
    avd = ui.adb('emu', 'avd', 'name').splitlines()[0].strip()
    if avd not in ('TV_Android_TV', 'TV_Google_TV'):
        raise RuntimeError('Expected a project TV emulator')
    if 'chain:enabled' not in ui.adb('shell', 'cmd', 'connectivity', 'get-chain3-enabled'):
        raise RuntimeError('Firewall is not enabled')
    if ':deny' not in ui.adb('shell', 'cmd', 'connectivity', 'get-package-networking-enabled', options.package):
        raise RuntimeError('Launcher networking is not blocked')
    home = (0, 'homeScreen')
    panel = (1, 'topPanel')
    night = (4, 'displayAndScreensaver')
    general = (6, 'generalSettings')
    ui.pages = [
        ('home-screen', [home]),
        ('weather', [panel, (1, 'topPanelObjects'), (3, 'informationGroup'), (3, 'weatherSettings')]),
        ('night', [night, (0, 'nightModeTitle')]),
        ('night-schedule', [night, (0, 'nightModeTitle'), (2, 'nightScheduleMenu')]),
        ('updates', [general, (1, 'appUpdates')]),
        ('backup', [general, (2, 'backupAndRestore')]),
    ]
    if options.only:
        selected = set(options.only.split(','))
        ui.pages = [(name, path) for name, path in ui.pages if name in selected]
        if selected != {name for name, _ in ui.pages}:
            raise ValueError('Unknown page name')
    passed = ui.run_checks()
    if options.solar_times:
        text = (ui.output / 'night-schedule.xml').read_text(encoding='utf-8')
        times = ('08:00', '20:00') if options.solar_times == 'defaults' else ('07:15', '18:45')
        if not all(value in text for value in times):
            raise AssertionError('Expected solar times missing from the actual Flutter schedule page')
    (ui.output / 'environment.json').write_text(json.dumps({
        'avd': avd, 'package': options.package,
        'internet': 'denied for launcher UID by Android firewall; Ethernet stays connected',
    }, ensure_ascii=False, indent=2), encoding='utf-8')
    raise SystemExit(0 if passed else 1)
