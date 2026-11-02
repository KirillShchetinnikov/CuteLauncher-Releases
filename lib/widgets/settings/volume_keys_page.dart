import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../../remote_mapping_configuration.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

String volumeModeLabel(AppLocalizations l, String mode) => switch (mode) {
  'auto' => l.volumeKeysAuto,
  'timed' => l.volumeKeysTimed,
  'repeat' => l.volumeKeysRepeat,
  _ => l.disabled,
};

class VolumeKeysPage extends StatefulWidget {
  const VolumeKeysPage({super.key});
  @override
  State<VolumeKeysPage> createState() => _VolumeKeysPageState();
}

class _VolumeKeysPageState extends State<VolumeKeysPage>
    with WidgetsBindingObserver {
  static const _bridge = BridgeChannel('cutelauncher/remote_mappings');
  RemoteMappingConfiguration _config = const RemoteMappingConfiguration();
  bool _busy = true, _loaded = false, _failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load([RemoteMappingConfiguration? save]) async {
    setState(() => _busy = true);
    try {
      final result = await _bridge
          .invokeMapMethod<String, dynamic>(
            save == null ? 'info' : 'save',
            save?.toMap(),
          )
          .timeout(const Duration(seconds: 10));
      if (result == null) throw StateError('Missing configuration');
      final next = RemoteMappingConfiguration.fromMap(result);
      if (mounted) {
        setState(() {
          _config = next;
          _loaded = true;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final enabled = _loaded && _config.enabled;
    return SettingsPageLayout(
      title: Text(l.volumeKeysTitle),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            title: l.volumeKeysMode,
            autofocus: true,
            value: _config.volumeMode,
            options: const ['auto', 'timed', 'repeat', 'off'],
            label: (mode) => volumeModeLabel(l, mode),
            enabled: enabled,
            onChanged: (mode) {
              if (!_busy) _load(_config.copyWith(volumeMode: mode));
            },
          ),
          SettingsChoiceTile<int>(
            title: l.volumeKeysDuration,
            value: _config.volumePauseSeconds,
            options: const [3, 5, 10, 15, 30],
            label: l.autoLaunchSeconds,
            enabled:
                enabled &&
                (_config.volumeMode == 'auto' || _config.volumeMode == 'timed'),
            onChanged: (seconds) {
              if (!_busy) _load(_config.copyWith(volumePauseSeconds: seconds));
            },
          ),
          if (_loaded && !_config.enabled)
            Text('${l.remoteMappingsEnabled}: ${l.disabled}'),
          if (_failed) Text(l.remoteMappingInvalid),
          if (_loaded) SettingsHelp(text: l.volumeKeysHelp),
        ],
      ),
    );
  }
}
