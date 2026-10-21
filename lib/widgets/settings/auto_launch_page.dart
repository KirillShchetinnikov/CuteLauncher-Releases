import 'settings_help.dart';
import '../../providers/tv_inputs_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_choice_tile.dart';
import 'settings_value_stepper.dart';
import '../rounded_switch_list_tile.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/apps_service.dart';
import '../application_list_icon.dart';

import '../../auto_launch_configuration.dart';
import '../../bridge_result.dart';
import '../../flauncher_channel.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tv_input.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class AutoLaunchPage extends StatefulWidget {
  static const routeName = 'auto_launch_panel';
  const AutoLaunchPage({super.key});
  @override
  State<AutoLaunchPage> createState() => _AutoLaunchPageState();
}

class _AutoLaunchPageState extends State<AutoLaunchPage>
    with WidgetsBindingObserver {
  static const _channel = BridgeChannel('cutelauncher/auto_launch');
  AutoLaunchConfiguration _config = const AutoLaunchConfiguration();
  bool _busy = true, _failed = false;
  String _ownPackage = '', _status = 'idle';
  List<Map<dynamic, dynamic>> _apps = [];
  List<TvInput> _inputs = [];
  bool _appsLoaded = false, _inputsLoaded = false;
  bool _inputsLoading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final info = await _channel
          .invokeMapMethod<String, dynamic>('info')
          .timeout(const Duration(seconds: 10));
      if (info == null) throw StateError('Auto launch bridge unavailable');
      if (!mounted) return;
      setState(() {
        _config = AutoLaunchConfiguration.fromMap(info);
        _ownPackage = info['ownPackage'] as String? ?? '';
        _status = info['status'] as String? ?? 'idle';
        _apps = _knownApps();
        _appsLoaded = context.read<AppsService?>() != null;
        _failed = false;
      });
      _loadInputLabel();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      setState(() => _busy = true);
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _save(AutoLaunchConfiguration config) async {
    if (_busy || !config.valid) return;
    setState(() => _busy = true);
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'save',
        config.toMap(),
      );
      if (mounted) {
        setState(() {
          _failed = result?['status'] != 'success';
          if (!_failed) {
            _config = config;
            _status = 'idle';
          }
        });
        _loadInputLabel();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<dynamic, dynamic>> _knownApps() => [
    for (final app in context.read<AppsService?>()?.applications ?? [])
      if (app.isLaunchable && app.packageName != _ownPackage)
        {'packageName': app.packageName, 'name': app.name},
  ];

  Future<void> _loadInputLabel() async {
    if (_config.mode != 'hdmi' || _inputsLoaded || _inputsLoading) return;
    _inputsLoading = true;
    try {
      await _choices('hdmi');
    } catch (_) {
      if (mounted) setState(() => _inputsLoaded = true);
    } finally {
      _inputsLoading = false;
    }
  }

  Future<List<(String, String)>> _choices(String mode) async {
    if (mode == 'app') {
      final known = _knownApps();
      final apps = known.isNotEmpty
          ? known
          : await FLauncherChannel().getApplications().timeout(
              const Duration(seconds: 10),
            );
      if (!mounted) return [];
      setState(() {
        _appsLoaded = true;
        _apps = apps.where((app) => app['launchable'] != false && app['packageName'] != _ownPackage).toList()
          ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
      });
      return [
        for (final app in _apps) ('${app['packageName']}', '${app['name']}'),
      ];
    }
    final inputs = await FLauncherChannel().getTvInputs().timeout(
      const Duration(seconds: 10),
    );
    if (!mounted) return [];
    setState(() {
      _inputsLoaded = true;
      _inputs = TvInput.ordered(
        inputs
            .map(TvInput.fromMap)
            .where((input) => input.type == TvInputType.hdmi),
      );
    });
    return [for (final input in context.read<TvInputsService?>()?.present(_inputs) ?? _inputs) (input.id, input.label)];
  }

  Future<String?> _pick(String mode) async {
    final l = AppLocalizations.of(context)!;
    final choices = _choices(mode);
    return showLauncherDialog<String>(
      context: context,
      builder: (context) => LauncherAlertDialog(
        title: Text(l.autoLaunchTarget),
        content: FutureBuilder<List<(String, String)>>(
          future: choices,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              );
            }
            final values = snapshot.data ?? [];
            if (values.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.autoLaunchUnavailable),
              );
            }
            return Column(
              children: [
                for (final choice in values)
                  FocusableSettingsTile(
                    autofocus: choice == values.first,
                    onPressed: () => Navigator.pop(context, choice.$1),
                    title: Text(choice.$2),
                    leading: mode == 'app'
                        ? context.read<AppsService?>() != null
                              ? ApplicationListIcon(packageName: choice.$1)
                              : const Icon(Icons.android, size: 32)
                        : null,
                  ),
              ],
            );
          },
        ),
        actions: [
          FutureBuilder<List<(String, String)>>(
            future: choices,
            builder: (context, snapshot) => LauncherDialogButton(
              autofocus:
                  snapshot.connectionState == ConnectionState.done &&
                  (snapshot.data ?? []).isEmpty,
              onPressed: () => Navigator.pop(context),
              isCancel: true,
              child: Text(l.cancel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mode(String mode) async {
    if (mode == _config.mode) return;
    var config = _config.copyWith(mode: mode);
    if (!config.valid) {
      final target = await _pick(mode);
      if (!mounted || target == null) return;
      config = mode == 'app'
          ? config.copyWith(app: target)
          : config.copyWith(input: target);
    }
    await _save(config);
  }

  String _target(AppLocalizations l) {
    if (_config.mode == 'app') {
      for (final app in _apps) {
        if (app['packageName'] == _config.app) return '${app['name']}';
      }
    } else {
      for (final input in context.read<TvInputsService?>()?.present(_inputs) ?? _inputs) {
        if (input.matchesId(_config.input)) return input.label;
      }
    }
    if (_config.mode == 'app') {
      return _appsLoaded ? l.autoLaunchUnavailable : _config.app;
    }
    return _inputsLoaded ? l.autoLaunchUnavailable : '…';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TvInputsService?>();
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(
        l.autoLaunchTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_failed || _status == 'unavailable')
            Text(l.autoLaunchUnavailable),
          if (_status == 'cancelled') Text(l.autoLaunchCancelled),
          SettingsChoiceTile<String>(
            title: l.autoLaunchTitle,
            value: _config.mode,
            options: const ['off', 'app', 'hdmi'],
            autofocus: true,
            enabled: !_busy,
            label: (mode) => switch (mode) {
              'app' => l.autoLaunchApp,
              'hdmi' => l.autoLaunchHdmi,
              _ => l.autoLaunchOff,
            },
            onChanged: _mode,
          ),
          if (_config.mode != 'off') ...[
            FocusableSettingsTile(
              title: Text(l.autoLaunchTarget),
              trailing: Text(_target(l)),
              onPressed: _busy
                  ? null
                  : () async {
                      final target = await _pick(_config.mode);
                      if (mounted && target != null) {
                        await _save(
                          _config.mode == 'app'
                              ? _config.copyWith(app: target)
                              : _config.copyWith(input: target),
                        );
                      }
                    },
            ),
            for (final event in [
              (l.autoLaunchBoot, true),
              (l.autoLaunchWake, false),
            ])
              RoundedSwitchListTile(
                title: Text(event.$1),
                enabled: !_busy,
                value: event.$2 ? _config.boot : _config.wake,
                onChanged: (value) => _save(
                  event.$2
                      ? _config.copyWith(boot: value)
                      : _config.copyWith(wake: value),
                ),
              ),
            SettingsValueStepper(
              title: l.autoLaunchDelay,
              value: _config.delay,
              enabled: !_busy,
              options: ({0, 3, 5, 10, 20, 30, 60, _config.delay}.toList()
                ..sort()),
              label: (v) => l.autoLaunchSeconds(v as int),
              onChanged: (v) => _save(_config.copyWith(delay: v as int)),
            ),
          ],
          const SizedBox(height: 16),
          SettingsHelp(text: l.autoLaunchHint),
        ],
      ),
    );
  }
}
