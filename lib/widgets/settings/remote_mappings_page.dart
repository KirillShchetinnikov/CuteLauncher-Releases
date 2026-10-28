import 'settings_help.dart';
import '../action_notice.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bridge_result.dart';
import '../../document_files.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../../remote_mapping_configuration.dart';
import '../application_list_icon.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_text_tile.dart';

const _bridge = BridgeChannel('cutelauncher/remote_mappings');

String remoteKeyLabel(AppLocalizations l, int code) => switch (code) {
  3 => 'Home',
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
  'recents' => l.remoteMappingRecents,
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
          if (_status != 'idle' && _status != 'success')
            Text(
              _status == 'busy'
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
  bool _importing = false;

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showLauncherDialog<bool>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(l.delete),
        content: Text(
          l.remoteMappingDeleteConfirm(_bindingLabel(l, widget.mapping!)),
        ),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            isCancel: true,
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final deleted = await widget.onDelete!();
    if (!mounted) return;
    setState(() => _saving = false);
    if (deleted) {
      Navigator.pop(context);
    } else {
      showActionNotice(context, l.remoteMappingDeleteFailed, error: true);
    }
  }

  @override
  void dispose() {
    _bridge.invokeMethod<void>('cancelLearn').catchError((Object _) {});
    super.dispose();
  }

  Future<void> _assign() async {
    final l = AppLocalizations.of(context)!;
    if (!widget.connected) {
      showActionNotice(context, l.remoteMappingServiceRequired, error: true);
      return;
    }
    final code = await showLauncherDialog<int>(
      context: context,
      builder: (_) => _ButtonCaptureDialog(initialKey: _key),
    );
    if (mounted && code != null) {
      setState(() {
        _key = code;
        if (code == 3) _trigger = 'hold';
      });
    }
  }

  Future<void> _importWebhook() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _importing = true);
    try {
      final source = await DocumentFiles.pickWebhookText();
      if (!mounted || source == null) return;
      final value = remoteWebhookFromText(source);
      if (value == null) {
        showActionNotice(context, l.remoteMappingImportInvalid, error: true);
      } else {
        setState(() => _target = value);
      }
    } catch (_) {
      if (mounted) {
        showActionNotice(context, l.remoteMappingImportFailed, error: true);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String? _validationError(AppLocalizations l) {
    if (_key == 0) return l.remoteMappingKeyRequired;
    if (_key == 3 && _trigger != 'hold') return l.remoteMappingHomeHoldRequired;
    if (widget.used.contains('$_key:$_trigger')) return l.remoteMappingConflict;
    if (_action == 'app' && _target.isEmpty) return l.remoteMappingAppRequired;
    if (_action == 'webhook') {
      if (_target.isEmpty) return l.remoteMappingUrlRequired;
      if (!remoteWebhookValid(_target)) return l.remoteMappingUrlInvalid;
    }
    return null;
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
                  leading: ApplicationListIcon(packageName: app.packageName),
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
    return Material(
      type: MaterialType.transparency,
      child: SettingsPageLayout(
        title: Text(l.remoteBindings),
        child: ListView(
          children: [
            SettingsTextTile(
              title: l.name,
              value: _name,
              emptyLabel: l.remoteMappingNamePlaceholder,
              enabled: !_saving && !_importing,
              maxLength: 80,
              onChanged: (value) => setState(() => _name = value.trim()),
            ),
            FocusableSettingsTile(
              title: Text(l.remoteMappingAssign),
              trailing: Text(
                _key == 0
                    ? l.settingsValueNotSet
                    : '${remoteKeyLabel(l, _key)} ($_key)',
              ),
              enabled: !_saving && !_importing,
              onPressed: _assign,
            ),
            if (widget.mapping != null)
              RoundedSwitchListTile(
                title: Text(l.remoteMappingsEnabled),
                value: _enabled,
                enabled: !_saving && !_importing,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            SettingsChoiceTile<String>(
              title: l.remoteMappingTrigger,
              value: _trigger,
              options: const ['press', 'hold'],
              enabled: !_importing && !_saving,
              label: (value) =>
                  value == 'hold' ? l.remoteMappingHold : l.remoteMappingPress,
              onChanged: (value) => setState(() {
                _trigger = value;
              }),
            ),
            if (_trigger == 'hold')
              SettingsHelp(
                text: _key == 3
                    ? l.recentAppsHomeHint
                    : l.remoteMappingHoldHint,
              ),
            SettingsChoiceTile<String>(
              title: l.remoteMappingAction,
              value: _action,
              options: const [
                'app',
                'home',
                'back',
                'webhook',
                'panel',
                'recents',
              ],
              label: (value) => _actionLabel(l, value),
              enabled: !_importing && !_saving,
              onChanged: (value) => setState(() {
                _action = value;
                _target = '';
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
                enabled: !_saving && !_importing,
                onPressed: _app,
              ),
            if (_action == 'webhook') ...[
              SettingsTextTile(
                enabled: !_saving && !_importing,
                title: 'Webhook URL',
                value: _target,
                obscureText: true,
                maxLength: 4096,
                keyboardType: TextInputType.url,
                onChanged: (value) => setState(() => _target = value.trim()),
              ),
              FocusableSettingsTile(
                title: Text(l.remoteMappingImport),
                leading: const Icon(Icons.file_open_outlined),
                enabled: !_saving && !_importing,
                onPressed: _importWebhook,
              ),
              SettingsHelp(text: l.remoteMappingImportHint),
            ],
            if (widget.onDelete != null)
              FocusableSettingsTile(
                title: Text(l.delete),
                leading: const Icon(Icons.delete_outline),
                enabled: !_saving && !_importing,
                onPressed: _delete,
              ),
            FocusableSettingsTile(
              title: Text(l.save),
              leading: const Icon(Icons.check),
              enabled: !_importing && !_saving,
              onPressed: () async {
                final error = _validationError(l);
                if (error != null) {
                  showActionNotice(context, error, error: true);
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
                    l.remoteMappingSaveFailed,
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

class _ButtonCaptureDialog extends StatefulWidget {
  final int initialKey;
  const _ButtonCaptureDialog({required this.initialKey});
  @override
  State<_ButtonCaptureDialog> createState() => _ButtonCaptureDialogState();
}

class _ButtonCaptureDialogState extends State<_ButtonCaptureDialog>
    with WidgetsBindingObserver {
  late int _captured = widget.initialKey;
  bool _learning = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancel() {
    _request++;
    _bridge.invokeMethod<void>('cancelLearn').catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancel();
      if (mounted) setState(() => _learning = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancel();
    super.dispose();
  }

  Future<void> _capture() async {
    final l = AppLocalizations.of(context)!;
    final request = ++_request;
    setState(() {
      _learning = true;
      _error = null;
    });
    try {
      final code = await _bridge
          .invokeMethod<int>('learn')
          .timeout(const Duration(seconds: 32));
      if (!mounted || request != _request) return;
      setState(() {
        if (code != null) {
          _captured = code;
        } else {
          _error = l.remoteMappingCaptureTimeout;
        }
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = l.remoteMappingCaptureFailed);
      }
    } finally {
      if (mounted && request == _request) {
        await _bridge
            .invokeMethod<void>('cancelLearn')
            .catchError((Object _) {});
        if (mounted && request == _request) setState(() => _learning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(l.remoteMappingAssign),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.remoteMappingCaptured(
              _captured == 0
                  ? l.settingsValueNotSet
                  : '${remoteKeyLabel(l, _captured)} ($_captured)',
            ),
          ),
          Text(
            _learning ? l.remoteMappingLearnHint : l.remoteMappingCaptureHint,
          ),
          if (_error != null) Text(_error!),
        ],
      ),
      actions: [
        LauncherDialogButton(
          autofocus: true,
          onPressed: _learning ? null : _capture,
          child: Text(l.remoteMappingCapture),
        ),
        LauncherDialogButton(
          isCancel: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          primary: true,
          onPressed: _captured == 0 || _learning
              ? null
              : () => Navigator.pop(context, _captured),
          child: Text(l.ok),
        ),
      ],
    );
  }
}
