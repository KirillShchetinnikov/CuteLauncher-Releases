import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/tv_inputs_configuration.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/providers/night_mode_configuration.dart';
import 'package:flauncher/providers/night_mode_service.dart' show nightModeKey;

void main() {
  final raw = [
    TvInput.fromMap({'id': 'port', 'label': 'HDMI 2', 'type': 1007}),
    TvInput.fromMap({
      'id': 'cec',
      'parentId': 'port',
      'label': 'XBOX',
      'type': 1007,
    }),
  ];
  test('own name wins over optional CEC name and standard name; icons and ids survive', () {
    const base = TvInputsConfiguration();
    expect(base.present(raw).single.label, 'XBOX');
    expect(
      base.copyWith(useCecNames: false).present(raw).single.label,
      'HDMI 2',
    );
    final own = base.copyWith(
      id: 'port',
      value: const TvInputOverride(name: 'Console', icon: 'game'),
    );
    for (final cec in [true, false]) {
      final config = TvInputsConfiguration.decode(
        own.copyWith(useCecNames: cec).encode(),
      );
      final input = config.present(raw).single;
      expect(input.label, 'Console');
      expect(input.icon, 'game');
      expect(input.id, 'port');
      expect(input.matchesId('cec'), isTrue);
      expect(input.portNumber, 2);
      expect(config.present([raw.first]).single.label, 'Console');
      expect(config.present([input]).single.label, 'Console');
    }
    final clear = own.copyWith(id: 'port', value: const TvInputOverride());
    expect(clear.present(own.present(raw)).single.label, 'XBOX');
    expect(
      clear.copyWith(useCecNames: false).present(own.present(raw)).single.label,
      'HDMI 2',
    );
    expect(clear.present([raw.first]).single.label, 'HDMI 2');
  });

  test('backup validates the bounded configuration and preserves unavailable input overrides', () {
    final config = const TvInputsConfiguration().copyWith(
      id: 'missing',
      value: const TvInputOverride(name: 'AV receiver', icon: 'receiver'),
    );
    final valid = compatibleSettings({
      tvInputsConfigurationKey: config.encode(),
    }, {});
    expect(
      TvInputsConfiguration.decode(valid[tvInputsConfigurationKey] as String)
          .overrides['missing']!
          .name,
      'AV receiver',
    );
    for (final value in [
      {'useCecNames': 1},
      {'overrides': []},
      {
        'overrides': {
          'port': {'icon': 'unsupported'},
        },
      },
      {
        'overrides': {
          '': {'name': 'bad'},
        },
      },
      {
        'overrides': {
          'port': {'name': List.filled(81, 'a').join()},
        },
      },
      {
        'overrides': {for (var i = 0; i < 129; i++) '$i': {}},
      },
    ]) {
      expect(() => TvInputsConfiguration.parse(value), throwsFormatException);
      expect(
        compatibleSettings({tvInputsConfigurationKey: jsonEncode(value)}, {}),
        isEmpty,
      );
    }
  });

  test('night input selection defaults to all, persists none/some, rejects malformed backup', () {
    const original = NightModeConfiguration(
      enabled: true,
      overrideMode: 'off',
      overrideUntil: 4000000000000,
    );
    expect(original.selectHdmiInputs, isFalse);
    expect(
      NightModeConfiguration.parse(
        original.toJson()
          ..remove('selectHdmiInputs')
          ..remove('ignoredHdmiInputIds'),
      ).selectHdmiInputs,
      isFalse,
    );
    for (final ids in [
      <String>[],
      ['port2', 'port2'],
    ]) {
      final c = original.copyWith(
        selectHdmiInputs: true,
        ignoredHdmiInputIds: ids,
      );
      final backup = compatibleSettings({
        nightModeKey: jsonEncode(c.toJson()),
      }, {});
      final decoded = NightModeConfiguration.decode(
        backup[nightModeKey] as String,
      );
      expect(decoded.selectHdmiInputs, isTrue);
      expect(decoded.ignoredHdmiInputIds, ids.toSet().toList());
      expect(decoded.overrideMode, 'off');
      expect(
        decoded.copyWith(ignoreHdmiInputs: false).ignoredHdmiInputIds,
        decoded.ignoredHdmiInputIds,
      );
    }
    for (final bad in [
      5,
      [5],
      [''],
      [List.filled(513, 'x').join()],
      List.filled(129, 'port'),
    ]) {
      expect(
        () => NightModeConfiguration.parse({
          ...original.toJson(),
          'ignoredHdmiInputIds': bad,
        }),
        throwsFormatException,
      );
    }
  });
}
