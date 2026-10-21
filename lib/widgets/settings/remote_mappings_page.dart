import 'settings_help.dart';
import '../action_notice.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../../remote_mapping_configuration.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_text_tile.dart';

const _bridge = BridgeChannel('cutelauncher/remote_mappings');

String remoteKeyLabel(AppLocalizations l, int code) => switch (code) {
  164 => 'Mute',
  288 => l.remoteMappingProfile,
  83 => l.settings,
  4001 => l.remoteMappingChannels,
  178 => l.inputs,
  167 => '${l.remoteMappingChannels} −',
  166 => '${l.remoteMappingChannels} +',
  4514 => l.remoteMappingQuickSettings,
  4056 => '123',
  165 => 'Info',
  4062 => 'Netflix',
  4099 => 'Prime Video',
  4140 => 'TCL Guard',
  4159 => 'Web',
  190 => 'YouTube',
  4020 => 'TCL Channel',
  4137 => 'TCL Home',
  _ => '${l.remoteMappingKey} $code',
};

String _actionLabel(AppLocalizations l, String value) => switch (value) {
  'app' => l.autoLaunchApp,
  'home' => l.homeButtonFix,
  'back' => l.remoteMappingBack,
  'webhook' => 'Webhook (POST)',
  'panel' => l.remotePanel,
  _ => value,
};

String _bindingLabel(AppLocalizations l, RemoteMapping item) =>
    '${item.name.isEmpty ? remoteKeyLabel(l, item.keyCode) : item.name}${item.trigger == 'hold' ? ' — ${l.remoteMappingHold}' : ''}';

class RemoteMappingsPage extends StatefulWidget {
  final bool switchOnly;
  const RemoteMappingsPage({super.key, this.switchOnly = false});
  @override
  State<RemoteMappingsPage> createState() => _RemoteMappingsPageState();
}

class _RemoteMappingsPageState extends State<RemoteMappingsPage>
    with WidgetsBindingObserver {
  RemoteMappingConfiguration _config = const RemoteMappingConfiguration();
  bool _busy = true, _failed = false, _loaded = false;
  bool _connected = false;
  String _status = 'idle';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.switchOnly) _editing(true);
    _load();
  }

  Future<void> _editing(bool value) async {
    try {
      await _bridge.invokeMethod<void>('editing', value);
    } catch (_) {
      /* no mapping mutation */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.switchOnly) _editing(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!widget.switchOnly) _editing(false);
    super.dispose();
  }

  Future<bool> _load([RemoteMappingConfiguration? save]) async {
    setState(() => _busy = true);
    try {
      final result = await _bridge
          .invokeMapMethod<String, dynamic>(
            save == null ? 'info' : 'save',
            save?.toMap(),
          )
          .timeout(const Duration(seconds: 10));
      if (result == null) throw StateError('Missing mappings');
      final config = RemoteMappingConfiguration.fromMap(result);
      if (mounted) {
        setState(() {
          _config = config;
          _loaded = true;
          _failed = false;
          _connected =
              result['permission'] == true && result['connected'] == true;
          _status = result['status'] as String? ?? 'idle';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return !_failed;
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showLauncherDialog<bool>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(l.remoteMappingsReset),
        content: Text(l.remoteMappingsResetConfirm),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            isCancel: true,
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.remoteMappingsReset),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _load(const RemoteMappingConfiguration());
    }
  }

  Future<void> _edit(RemoteMapping? mapping) async {
    await Navigator.of(context).push<void>(
      SettingsRoute(
        builder: (_) => _MappingEditor(
          mapping: mapping,
          used: _config.bindings
              .where((item) => item.slot != mapping?.slot)
              .map((item) => item.slot)
              .toSet(),
          connected: _connected,
          onSave: (value) => _load(
            (mapping == null
                    ? _config
                    : _config.remove(mapping.keyCode, mapping.trigger))
                .replace(value),
          ),
          onDelete: mapping == null
              ? null
              : () => _load(_config.remove(mapping.keyCode, mapping.trigger)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final master = RoundedSwitchListTile(
      value: _config.enabled,
      enabled: _loaded && !_busy,
      title: Text(l.remoteMappingsEnabled),
      onChanged: (value) => _load(
        RemoteMappingConfiguration(enabled: value, bindings: _config.bindings),
      ),
    );
    if (widget.switchOnly) {
      return Column(
        children: [master, if (_failed) Text(l.remoteMappingInvalid)],
      );
    }
    return SettingsPageLayout(
      title: Text(l.remoteBindings),
      child: ListView(
        children: [
          FocusableSettingsTile(
            title: Text(l.remoteMappingsAdd),
            leading: const Icon(Icons.add),
            enabled: _loaded && !_busy && _config.bindings.length < 64,
            onPressed: () => _edit(null),
          ),
          for (final item in _config.bindings)
            FocusableSettingsTile(
              title: Text(_bindingLabel(l, item)),
              trailing: Text(
                '${_actionLabel(l, item.action)} · ${item.enabled ? l.enabled : l.disabled}',
              ),
              enabled: !_busy,
              onPressed: () => _edit(item),
            ),
          if (_status != 'idle')
            Text(
              _status == 'success'
                  ? l.actionCompleted
                  : _status == 'busy'
                  ? l.loading
                  : l.autoLaunchUnavailable,
            ),
          if (_failed) Text(l.remoteMappingInvalid),
          FocusableSettingsTile(
            title: Text(l.remoteMappingsReset),
            enabled: !_busy,
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}

class RemoteMappingsSwitch extends StatelessWidget {
  const RemoteMappingsSwitch({super.key});
  @override
  Widget build(BuildContext context) =>
      const RemoteMappingsPage(switchOnly: true);
}

class _MappingEditor extends StatefulWidget {
  final RemoteMapping? mapping;
  final Set<String> used;
  final bool connected;
  final Future<bool> Function(RemoteMapping) onSave;
  final Future<bool> Function()? onDelete;
  const _MappingEditor({
    this.mapping,
    required this.used,
    required this.connected,
    required this.onSave,
    this.onDelete,
  });
  @override
  State<_MappingEditor> createState() => _MappingEditorState();
}

class _MappingEditorState extends State<_MappingEditor> {
  late int _key = widget.mapping?.keyCode ?? 0;
  late String _action = widget.mapping?.action ?? 'home';
  late String _target = widget.mapping?.target ?? '';
  late String _trigger = widget.mapping?.trigger ?? 'press';
  late String _name = widget.mapping?.name ?? '';
  late bool _enabled = widget.mapping?.enabled ?? true;
  bool _saving = false;
  bool _learning = false, _invalid = false;
  @override
  void dispose() {
    _bridge.invokeMethod<void>('cancelLearn').catchError((Object _) {});
    super.dispose();
  }

  Future<void> _learn() async {
    setState(() {
      _learning = true;
      _invalid = false;
    });
    try {
      final code = await _bridge
          .invokeMethod<int>('learn')
          .timeout(const Duration(seconds: 32));
      if (mounted && code != null) {
        setState(() {
          _key = code;
          _invalid = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _invalid = true);
    } finally {
      if (mounted) setState(() => _learning = false);
    }
  }

  Future<void> _app() async {
    final l = AppLocalizations.of(context)!;
    final apps =
        context
            .read<AppsService?>()
            ?.applications
            .where((app) => app.isLaunchable)
            .toList() ??
        [];
    final value = await showLauncherDialog<String>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(l.applications),
        content: SizedBox(
          width: 420,
          height: 360,
          child: ListView(
            children: [
              if (apps.isEmpty) Text(l.autoLaunchUnavailable),
              for (final app in apps)
                FocusableSettingsTile(
                  title: Text(app.name),
                  autofocus:
                      app.packageName == _target ||
                      _target.isEmpty && app == apps.first,
                  onPressed: () => Navigator.pop(dialog, app.packageName),
                ),
            ],
          ),
        ),
        actions: [
          LauncherDialogButton(
            isCancel: true,
            onPressed: () => Navigator.pop(dialog),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
    if (mounted && value != null) setState(() => _target = value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = {
      0,
      if (_key != 0) _key,
      for (final key in [
        164,
        288,
        83,
        4001,
        178,
        167,
        166,
        4514,
        4056,
        165,
        4062,
        4099,
        4140,
        4159,
        190,
        4020,
        4137,
      ])
        key,
    }.toList();
    return Material(
      type: MaterialType.transparency,
      child: SettingsPageLayout(
        title: Text(l.remoteBindings),
        child: ListView(
          children: [
            SettingsTextTile(
              title: l.name,
              value: _name,
              enabled: !_saving && !_learning,
              maxLength: 80,
              onChanged: (value) => setState(() => _name = value.trim()),
            ),
            if (widget.mapping != null)
              RoundedSwitchListTile(
                title: Text(l.remoteMappingsEnabled),
                value: _enabled,
                enabled: !_saving,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            SettingsChoiceTile<String>(
              title: l.remoteMappingTrigger,
              value: _trigger,
              options: const ['press', 'hold'],
              enabled: !_learning && !_saving,
              label: (value) =>
                  value == 'hold' ? l.remoteMappingHold : l.remoteMappingPress,
              onChanged: (value) => setState(() {
                _trigger = value;
                _invalid = false;
              }),
            ),
            if (_trigger == 'hold') SettingsHelp(text: l.remoteMappingHoldHint),
            SettingsChoiceTile<int>(
              title: l.remoteMappingKey,
              value: _key,
              options: [0, -1, ...options.where((key) => key != 0)],
              autofocus: true,
              enabled: !_learning && !_saving,
              label: (key) => key == -1
                  ? l.remoteMappingLearn
                  : key == 0
                  ? l.settingsValueNotSet
                  : '${remoteKeyLabel(l, key)} ($key)',
              onChanged: (key) {
                if (key == -1) {
                  if (widget.connected) {
                    _learn();
                  } else {
                    showActionNotice(
                      context,
                      l.remoteMappingInvalid,
                      error: true,
                    );
                  }
                  return;
                }
                setState(() {
                  _key = key;
                  _invalid = false;
                });
              },
            ),
            if (_learning) Text(l.remoteMappingLearnHint),
            SettingsChoiceTile<String>(
              title: l.remoteMappingAction,
              value: _action,
              options: const ['app', 'home', 'back', 'webhook', 'panel'],
              label: (value) => _actionLabel(l, value),
              enabled: !_learning && !_saving,
              onChanged: (value) => setState(() {
                _action = value;
                _target = '';
                _invalid = false;
              }),
            ),
            if (_action == 'app')
              FocusableSettingsTile(
                title: Text(l.applications),
                trailing: Text(
                  context
                          .read<AppsService?>()
                          ?.applications
                          .where((app) => app.packageName == _target)
                          .firstOrNull
                          ?.name ??
                      (_target.isEmpty ? l.settingsValueNotSet : _target),
                ),
                onPressed: _app,
              ),
            if (_action == 'webhook')
              SettingsTextTile(
                title: 'Webhook URL',
                value: _target,
                obscureText: true,
                maxLength: 4096,
                keyboardType: TextInputType.url,
                onChanged: (value) => setState(() => _target = value.trim()),
              ),
            if (_invalid) Text(l.remoteMappingInvalid),
            if (widget.onDelete != null)
              FocusableSettingsTile(
                title: Text(l.delete),
                leading: const Icon(Icons.delete_outline),
                enabled: !_saving && !_learning,
                onPressed: () async {
                  setState(() => _saving = true);
                  final deleted = await widget.onDelete!();
                  if (!context.mounted) return;
                  setState(() => _saving = false);
                  if (deleted) {
                    Navigator.pop(context);
                  } else {
                    showActionNotice(
                      context,
                      l.remoteMappingInvalid,
                      error: true,
                    );
                  }
                },
              ),
            FocusableSettingsTile(
              title: Text(l.save),
              leading: const Icon(Icons.check),
              enabled: !_learning && !_saving,
              onPressed: () async {
                if (_key == 0 ||
                    widget.used.contains('$_key:$_trigger') ||
                    (_action == 'app' || _action == 'webhook') &&
                        _target.isEmpty ||
                    _action == 'webhook' && !remoteWebhookValid(_target)) {
                  showActionNotice(
                    context,
                    widget.used.contains('$_key:$_trigger')
                        ? l.remoteMappingConflict
                        : l.remoteMappingInvalid,
                    error: true,
                  );
                  return;
                }
                setState(() => _saving = true);
                final saved = await widget.onSave(
                  RemoteMapping(
                    name: _name,
                    keyCode: _key,
                    action: _action,
                    target: _target,
                    trigger: _trigger,
                    enabled: _enabled,
                  ),
                );
                if (!context.mounted) return;
                setState(() => _saving = false);
                if (saved) {
                  Navigator.pop(context);
                } else {
                  showActionNotice(
                    context,
                    l.remoteMappingInvalid,
                    error: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
