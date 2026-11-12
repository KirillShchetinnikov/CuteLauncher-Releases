import 'settings_information.dart';
import 'settings_read_only_value.dart';
import 'settings_section.dart';
import 'settings_help.dart';
import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'cloud_error_message.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/cloud_backup_service.dart';

import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class CloudBackupPage extends StatefulWidget {
  static const routeName = 'cloud_backup';
  const CloudBackupPage({super.key, this.smb = false});
  final bool smb;
  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage>
    with WidgetsBindingObserver {
  final _url = TextEditingController(),
      _user = TextEditingController(),
      _password = TextEditingController();
  late CloudBackupService _service;
  bool _busy = false;
  int _generation = 0;
  String? _message;
  bool _messageFailed = false;
  TextEditingController? _activeSecretEditor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = context.read<CloudBackupService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _run(() async {
          await _service.refreshAccount();
          if (!mounted) return;
          _url.text = _service.account.url;
          _user.text = _service.account.user;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _generation++;
      _password.clear();
      _activeSecretEditor?.clear();
      if (_busy) _service.cancel();
    }
  }

  bool _current(int generation) => mounted && generation == _generation;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _message = null;
      _messageFailed = false;
    });
    try {
      await action();
    } catch (error) {
      if (mounted && _current(generation)) {
        final l = AppLocalizations.of(context)!;
        _message = cloudErrorMessage(l, error, smb: widget.smb);
        _messageFailed = true;
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(String message) async =>
      await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) {
          final l = AppLocalizations.of(dialog)!;
          return LauncherAlertDialog(
            content: Text(message),
            actions: [
              LauncherDialogButton(
                autofocus: true,
                onPressed: () => Navigator.pop(dialog, false),
                isCancel: true,
                child: Text(l.cancel),
              ),
              LauncherDialogButton(
                primary: true,
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(l.cloudDisconnect),
              ),
            ],
          );
        },
      ) ==
      true;
  Future<void> _connect() => _run(() async {
    final generation = _generation;
    final l = AppLocalizations.of(context)!;
    try {
      await _service.signIn(_url.text.trim(), _user.text, _password.text);
      if (_current(generation)) {
        _message = l.cloudSuccess;
      }
    } finally {
      if (mounted) _password.clear();
    }
  });
  Future<void> _disconnect() => _run(() async {
    final generation = _generation;
    final l = AppLocalizations.of(context)!;
    if (!await _confirm(l.cloudDisconnectConfirm) || !_current(generation)) {
      return;
    }
    await _service.disconnect();
    if (_current(generation)) {
      _password.clear();
      _url.clear();
      _user.clear();
      _message = l.cloudSuccess;
    }
  });
  Widget _labelledInput(String label, TextField field) => FocusableSettingsTile(
    key: ValueKey('${(field.key as ValueKey).value}-button'),
    title: Text(label),
    enabled: field.enabled == true,
    valueIcon: Icons.edit_outlined,
    trailing: Text(
      field.obscureText
          ? (field.controller!.text.isEmpty
                ? AppLocalizations.of(context)!.settingsValueNotSet
                : '••••••')
          : (field.controller!.text.isEmpty
                ? AppLocalizations.of(context)!.settingsValueNotSet
                : field.controller!.text),
      overflow: TextOverflow.ellipsis,
    ),
    onPressed: field.enabled == true
        ? () async {
            final editor = TextEditingController(text: field.controller!.text);
            if (field.obscureText) _activeSecretEditor = editor;
            final l = AppLocalizations.of(context)!;
            try {
              final value = await showLauncherDialog<String>(
                context: context,
                builder: (dialog) => LauncherAlertDialog(
                  title: Text(label),
                  content: _input(
                    TextField(
                      key: field.key,
                      controller: editor,
                      autofocus: true,
                      maxLength: field.maxLength,
                      keyboardType: field.keyboardType,
                      obscureText: field.obscureText,
                      autocorrect: false,
                      enableSuggestions: !field.obscureText,
                    ),
                  ),
                  actions: [
                    LauncherDialogButton(
                      onPressed: () => Navigator.pop(dialog),
                      isCancel: true,
                      child: Text(l.cancel),
                    ),
                    LauncherDialogButton(
                      primary: true,
                      onPressed: () => Navigator.pop(dialog, editor.text),
                      child: Text(l.ok),
                    ),
                  ],
                ),
              );
              if (value != null && mounted) {
                setState(() => field.controller!.text = value);
              }
            } finally {
              if (identical(_activeSecretEditor, editor)) {
                _activeSecretEditor = null;
              }
              editor.dispose();
            }
          }
        : null,
  );
  Widget _input(TextField field) => RemoteTextInput(child: field);
  bool get _hasCredentials =>
      _url.text.trim().isNotEmpty &&
      _user.text.trim().isNotEmpty &&
      _password.text.trim().isNotEmpty;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<CloudBackupService>();
    final enabled = !_busy && !service.busy;
    Widget action(
      String label,
      IconData icon,
      VoidCallback onPressed, {
      bool available = true,
    }) => FocusableSettingsTile(
      leading: Icon(icon),
      title: Text(label),
      enabled: enabled && available,
      onPressed: enabled && available ? onPressed : null,
    );
    return SettingsPageLayout(
      title: Text(widget.smb ? l.backupSmb : 'WebDAV / Nextcloud'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.smb) SettingsHelp(title: l.backupSmb, text: l.smbHelp),
            SettingsSection(
              key: const ValueKey('settingsGroupCredentials'),
              title: l.settingsGroupCredentials,
              children: [
                _labelledInput(
                  widget.smb ? l.smbUrl : l.cloudUrl,
                  TextField(
                    key: const ValueKey('cloud-url'),
                    controller: _url,
                    enabled: enabled,
                    maxLength: 2048,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(),
                  ),
                ),
                _labelledInput(
                  l.cloudUser,
                  TextField(
                    key: const ValueKey('cloud-user'),
                    controller: _user,
                    enabled: enabled,
                    maxLength: 256,
                    autocorrect: false,
                    decoration: const InputDecoration(),
                  ),
                ),
                _labelledInput(
                  widget.smb ? l.smbPassword : l.cloudPassword,
                  TextField(
                    key: const ValueKey('cloud-password'),
                    controller: _password,
                    enabled: enabled,
                    maxLength: 4096,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(),
                  ),
                ),
              ],
            ),
            SettingsSection(
              key: const ValueKey('networkConnection'),
              title: l.networkConnection,
              children: [
                SettingsMessage(
                  text: service.account.configured
                      ? l.backupConfigured
                      : l.backupNotConfigured,
                ),
                if (service.account.configured) ...[
                  const SizedBox(height: 12),
                  SettingsReadOnlyValue(
                    label: widget.smb ? l.smbUrl : l.cloudUrl,
                    value: service.account.url,
                    textDirection: TextDirection.ltr,
                  ),
                  SettingsReadOnlyValue(
                    label: l.cloudUser,
                    value: service.account.user,
                  ),
                ],
                action(
                  l.cloudConnect,
                  Icons.link,
                  _connect,
                  available: _hasCredentials,
                ),
                if (service.account.configured) ...[
                  action(
                    l.cloudCheck,
                    Icons.refresh,
                    () => _run(() async {
                      await service.checkAccount();
                      if (mounted) _message = l.cloudSuccess;
                    }),
                  ),
                ],
                action(
                  l.cloudDisconnect,
                  Icons.link_off,
                  _disconnect,
                  available: service.account.configured,
                ),
                SizedBox(child: _busy ? const LinearProgressIndicator() : null),
                if (_message != null)
                  SettingsMessage(
                    text: _message!,
                    kind: _messageFailed
                        ? SettingsMessageKind.error
                        : SettingsMessageKind.info,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    if (_busy) _service.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _url.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }
}
