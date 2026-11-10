import 'package:flutter/material.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';

class RenderCompatibilityTile extends StatefulWidget {
  const RenderCompatibilityTile({super.key});

  @override
  State<RenderCompatibilityTile> createState() =>
      _RenderCompatibilityTileState();
}

class _RenderCompatibilityTileState extends State<RenderCompatibilityTile> {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  Map<String, dynamic>? _state;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _update();
  }

  Future<void> _update([bool? enabled]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final state = await _channel.invokeMapMethod<String, dynamic>(
        enabled == null ? 'getRenderCompatibility' : 'setRenderCompatibility',
        enabled == null ? null : {'enabled': enabled},
      );
      if (state == null ||
          ['automatic', 'enabled', 'active'].any((k) => state[k] is! bool)) {
        throw StateError('Invalid render compatibility state');
      }
      if (mounted) setState(() => _state = state);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (await _channel.invokeMethod<bool>('applyRenderCompatibility') !=
          true) {
        throw StateError('Restart failed');
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
    final state = _state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state == null)
          FocusableSettingsTile(
            title: Text(
              '${l.renderCompatibilityTitle}\n${_failed ? l.renderCompatibilityFailed : l.loading}',
            ),
            busy: _busy,
            onPressed: _update,
          )
        else ...[
          if (state['automatic'] == true)
            FocusableSettingsTile(
              title: Text(
                '${l.renderCompatibilityTitle}\n${l.renderCompatibilityAutomatic}',
              ),
              enabled: false,
            )
          else
            RoundedSwitchListTile(
              title: Text(l.renderCompatibilityTitle),
              secondary: const Icon(Icons.display_settings),
              value: state['enabled'] == true,
              busy: _busy,
              onChanged: _update,
            ),
          if (state['enabled'] != state['active'])
            FocusableSettingsTile(
              leading: const Icon(Icons.refresh),
              title: Text(l.renderCompatibilityApply),
              busy: _busy,
              onPressed: _apply,
            ),
          if (_failed) Text(l.renderCompatibilityFailed),
        ],
        SettingsHelp(
          title: l.renderCompatibilityTitle,
          text: l.renderCompatibilityHelp,
        ),
      ],
    );
  }
}
