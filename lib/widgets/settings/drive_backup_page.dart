import 'settings_help.dart';
import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../cloud_account.dart';
import 'cloud_error_message.dart';
import '../../providers/drive_backup_service.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class DriveBackupPage extends StatefulWidget {
  const DriveBackupPage({super.key});
  @override
  State<DriveBackupPage> createState() => _DriveBackupPageState();
}

class _DriveBackupPageState extends State<DriveBackupPage>
    with WidgetsBindingObserver {
  String _id = '', _secret = '';
  TextEditingController? _activeSecretEditor;
  late DriveBackupService _service;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final service = context.read<DriveBackupService>();
    _service = service;
    _id = service.clientId;
    _secret = service.clientSecret;
  }

  Future<void> _edit(bool secret) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: secret ? _secret : _id);
    if (secret) _activeSecretEditor = controller;
    try {
      final value = await showLauncherDialog<String>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(secret ? l.backupClientSecret : l.backupClientId),
          content: RemoteTextInput(
            child: TextField(
              controller: controller,
              autofocus: true,
              obscureText: secret,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 256,
              onSubmitted: (value) => Navigator.pop(dialog, value.trim()),
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
              onPressed: () => Navigator.pop(dialog, controller.text.trim()),
              child: Text(l.ok),
            ),
          ],
        ),
      );
      if (value != null && mounted) {
        setState(() {
          if (secret) {
            _secret = value;
          } else {
            _id = value;
          }
        });
      }
    } finally {
      if (identical(_activeSecretEditor, controller)) {
        _activeSecretEditor = null;
      }
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<DriveBackupService>();
    final canConnect =
        !service.busy && _id.trim().isNotEmpty && _secret.trim().isNotEmpty;
    final canDisconnect = !service.busy && service.configured;
    return SettingsPageLayout(
      title: Text(l.backupGoogleDrive),
      child: ListView(
        children: [
          SettingsHelp(text: l.backupDriveHelp),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              service.configured ? l.backupConfigured : l.backupNotConfigured,
            ),
          ),
          FocusableSettingsTile(
            title: Text(l.backupClientId),
            valueIcon: Icons.edit_outlined,
            trailing: Text(
              _id.isEmpty ? l.settingsValueNotSet : _id,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: service.busy ? null : () => _edit(false),
          ),
          FocusableSettingsTile(
            title: Text(l.backupClientSecret),
            valueIcon: Icons.edit_outlined,
            trailing: Text(_secret.isEmpty ? l.settingsValueNotSet : '••••••'),
            onPressed: service.busy ? null : () => _edit(true),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.link),
            title: Text(l.cloudConnect),
            enabled: canConnect,
            onPressed: !canConnect
                ? null
                : () async {
                    try {
                      await service.connect(_id, _secret);
                    } catch (error) {
                      if (context.mounted) {
                        final message = cloudErrorMessage(
                          l,
                          error,
                          drive: true,
                        );
                        if (message == null) return;
                        showActionNotice(context, message, error: true);
                      }
                    }
                  },
          ),
          if (service.code.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                '${service.verificationUrl}\n${service.code}',
              ),
            ),
          if (service.busy) const LinearProgressIndicator(),
          if (service.failed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                cloudErrorMessage(
                      l,
                      CloudBackupException(service.failureCode ?? 'unknown'),
                      drive: true,
                    ) ??
                    l.cloudFailed,
              ),
            ),
          if (service.busy)
            FocusableSettingsTile(
              title: Text(l.cancel),
              onPressed: service.cancel,
            ),
          FocusableSettingsTile(
            leading: const Icon(Icons.link_off),
            title: Text(l.cloudDisconnect),
            enabled: canDisconnect,
            onPressed: !canDisconnect
                ? null
                : () async {
                    try {
                      await service.disconnect();
                      if (mounted) {
                        setState(() {
                          _id = '';
                          _secret = '';
                        });
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showActionNotice(
                          context,
                          l.cloudStorageError,
                          error: true,
                        );
                      }
                    }
                  },
          ),
          if (service.code.isNotEmpty)
            Center(
              child: QrImageView(
                data: service.verificationUrl,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.cancel();
    _secret = '';
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (mounted) setState(() => _secret = '');
      _activeSecretEditor?.clear();
    }
  }
}
