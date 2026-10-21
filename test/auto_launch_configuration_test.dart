import 'package:flauncher/auto_launch_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default is off and local target configuration round trips', () {
    const config = AutoLaunchConfiguration();
    expect(config.mode, 'off');
    expect(config.boot || config.wake, isFalse);
    final selected = config.copyWith(
      mode: 'app',
      app: 'sample.player',
      boot: true,
      delay: 30,
    );
    expect(selected.valid, isTrue);
    expect(
      AutoLaunchConfiguration.fromMap(selected.toMap()).toMap(),
      selected.toMap(),
    );
    expect(selected.copyWith(mode: 'off').app, 'sample.player');
  });
  test(
    'invalid inputs are disabled rather than converted to another target',
    () {
      for (final change in [
        {'mode': 'app'},
        {'mode': 'hdmi'},
        {'mode': 'unknown'},
        {'delay': -1},
        {'delay': 61},
        {'delay': '5'},
        {'wake': 1},
        {'app': '../bad'},
        {'input': 'x' * 513},
      ]) {
        expect(
          AutoLaunchConfiguration.fromMap({
            ...const AutoLaunchConfiguration().toMap(),
            ...change,
          }).mode,
          'off',
        );
      }
      expect(
        const AutoLaunchConfiguration(mode: 'hdmi', input: 'OEM/HDMI1').valid,
        isTrue,
      );
    },
  );
}
