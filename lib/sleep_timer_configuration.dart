import 'dart:convert';

const sleepTimerConfigurationKey = 'sleep_timer_configuration';
const defaultSleepTimerMinutes = [
  10,
  20,
  30,
  40,
  50,
  60,
  90,
  120,
  180,
  240,
  300,
  360,
];
// Six hour digits, plus minutes and seconds. Fits Dart and Android arithmetic.
const maxSleepTimerSeconds = 3599999999;

bool validSleepTimerSeconds(int seconds) =>
    seconds > 0 && seconds <= maxSleepTimerSeconds;

class SleepTimerPreset {
  final String id;
  final int seconds;
  final bool visible;
  const SleepTimerPreset(this.id, this.seconds, {this.visible = true});
  Map<String, Object> toJson() => {
    'id': id,
    'seconds': seconds,
    'visible': visible,
  };
}

class SleepTimerConfiguration {
  final String display;
  final bool showSeconds, closeAfterSelection;
  final List<SleepTimerPreset> presets;

  SleepTimerConfiguration({
    this.display = 'remaining',
    this.showSeconds = true,
    this.closeAfterSelection = true,
    List<SleepTimerPreset>? presets,
  }) : presets = List.unmodifiable(presets ?? defaults);

  static List<SleepTimerPreset> get defaults => [
    const SleepTimerPreset('default_30', 30),
    for (final minutes in defaultSleepTimerMinutes)
      SleepTimerPreset('default_${minutes * 60}', minutes * 60),
  ];

  SleepTimerConfiguration copyWith({
    String? display,
    bool? showSeconds,
    bool? closeAfterSelection,
    List<SleepTimerPreset>? presets,
  }) => SleepTimerConfiguration(
    display: display ?? this.display,
    showSeconds: showSeconds ?? this.showSeconds,
    closeAfterSelection: closeAfterSelection ?? this.closeAfterSelection,
    presets: presets ?? this.presets,
  );

  static SleepTimerConfiguration parse(String encoded) {
    final value = jsonDecode(encoded);
    if (value is! Map ||
        !['remaining', 'end', 'both'].contains(value['display']) ||
        value['showSeconds'] is! bool ||
        value['closeAfterSelection'] is! bool ||
        value['presets'] is! List) {
      throw const FormatException('Invalid timer configuration');
    }
    final ids = <String>{};
    final presets = <SleepTimerPreset>[];
    for (final item in value['presets']) {
      if (item is! Map ||
          item['id'] is! String ||
          (item['id'] as String).isEmpty ||
          !ids.add(item['id'] as String) ||
          item['seconds'] is! int ||
          !validSleepTimerSeconds(item['seconds'] as int) ||
          item['visible'] is! bool) {
        throw const FormatException('Invalid timer preset');
      }
      presets.add(
        SleepTimerPreset(item['id'], item['seconds'], visible: item['visible']),
      );
    }
    return SleepTimerConfiguration(
      display: value['display'],
      showSeconds: value['showSeconds'],
      closeAfterSelection: value['closeAfterSelection'],
      presets: [
        ...presets.where((p) => p.visible),
        ...presets.where((p) => !p.visible),
      ],
    );
  }

  static SleepTimerConfiguration decode(String? encoded) {
    try {
      return parse(encoded ?? '');
    } catch (_) {
      return SleepTimerConfiguration();
    }
  }

  String encode() => jsonEncode({
    'display': display,
    'showSeconds': showSeconds,
    'closeAfterSelection': closeAfterSelection,
    'presets': presets.map((p) => p.toJson()).toList(),
  });

  SleepTimerConfiguration move(String id, int direction) {
    if (direction != -1 && direction != 1) return this;
    final visible = presets.where((p) => p.visible).toList();
    final hidden = presets.where((p) => !p.visible).toList();
    final index = presets.indexWhere((p) => p.id == id);
    if (index < 0) return this;
    final item = presets[index];
    final list = item.visible ? visible : hidden;
    final at = list.indexWhere((p) => p.id == id);
    final next = at + direction;
    if (next >= 0 && next < list.length) {
      list.removeAt(at);
      list.insert(next, item);
    } else if (item.visible && direction == 1) {
      visible.removeAt(at);
      hidden.insert(0, SleepTimerPreset(id, item.seconds, visible: false));
    } else if (!item.visible && direction == -1) {
      hidden.removeAt(at);
      visible.add(SleepTimerPreset(id, item.seconds));
    }
    return copyWith(presets: [...visible, ...hidden]);
  }
}

String formatTimerDuration(int seconds, {bool showSeconds = true}) {
  // Round up when seconds are hidden, so an active timer never reads zero minutes.
  final value = showSeconds ? seconds : ((seconds + 59) ~/ 60) * 60;
  final hours = value ~/ 3600;
  final minutes = (value ~/ 60 % 60).toString().padLeft(2, '0');
  final secs = (value % 60).toString().padLeft(2, '0');
  if (!showSeconds) return '$hours:$minutes';
  return '${hours > 0 ? '$hours:' : ''}$minutes:$secs';
}
