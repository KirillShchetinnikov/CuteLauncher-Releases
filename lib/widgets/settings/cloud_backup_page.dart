import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/action_notice.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'cloud_error_message.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/cloud_backup_service.dart';

import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class CloudBackupPage extends StatefulWidget {
  static const routeName = 'cloud_backup';
  const CloudBackupPage({super.key});
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
    });
    var failed = false;
    try {
      await action();
    } catch (error) {
      failed = true;
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        _message = cloudErrorMessage(l, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_current(generation) && _message != null) {
          showActionNotice(context, _message!, error: failed);
        }
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
                child: Text(l.ok),
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
      title: const Text('WebDAV / Nextcloud'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (service.account.configured) ...[
              const SizedBox(height: 12),
              Text(service.account.url),
              Text(service.account.user),
            ],
            _labelledInput(
              l.cloudUrl,
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
              l.cloudPassword,
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
            if (_busy) const LinearProgressIndicator(),
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
