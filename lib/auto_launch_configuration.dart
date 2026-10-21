class AutoLaunchConfiguration {
  final String mode, app, input;
  final bool boot, wake;
  final int delay;
  const AutoLaunchConfiguration({
    this.mode = 'off',
    this.app = '',
    this.input = '',
    this.boot = false,
    this.wake = false,
    this.delay = 5,
  });
  bool get valid =>
      ['off', 'app', 'hdmi'].contains(mode) &&
      delay >= 0 &&
      delay <= 60 &&
      input.length <= 512 &&
      app.length <= 255 &&
      (app.isEmpty ||
          RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$')
              .hasMatch(app)) &&
      (mode == 'off' ||
          mode == 'app' && app.isNotEmpty ||
          mode == 'hdmi' && input.isNotEmpty);
  Map<String, Object> toMap() => {
    'mode': mode,
    'app': app,
    'input': input,
    'boot': boot,
    'wake': wake,
    'delay': delay,
  };
  static AutoLaunchConfiguration fromMap(Map<String, dynamic> map) {
    try {
      final config = AutoLaunchConfiguration(
        mode: map['mode'] as String? ?? 'off',
        app: map['app'] as String? ?? '',
        input: map['input'] as String? ?? '',
        boot: map['boot'] as bool? ?? false,
        wake: map['wake'] as bool? ?? false,
        delay: map['delay'] as int? ?? 5,
      );
      return config.valid ? config : const AutoLaunchConfiguration();
    } catch (_) {
      return const AutoLaunchConfiguration();
    }
  }

  AutoLaunchConfiguration copyWith({
    String? mode,
    String? app,
    String? input,
    bool? boot,
    bool? wake,
    int? delay,
  }) => AutoLaunchConfiguration(
    mode: mode ?? this.mode,
    app: app ?? this.app,
    input: input ?? this.input,
    boot: boot ?? this.boot,
    wake: wake ?? this.wake,
    delay: delay ?? this.delay,
  );
}
