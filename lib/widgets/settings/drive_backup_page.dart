import 'settings_section.dart';
import '../../document_files.dart';
import '../../drive_client_configuration.dart';
import 'settings_help.dart';
import 'settings_read_only_value.dart';
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
  const DriveBackupPage({super.key, this.pickClient});

  final Future<String?> Function(BuildContext)? pickClient;
  @override
  State<DriveBackupPage> createState() => _DriveBackupPageState();
}

class _DriveBackupPageState extends State<DriveBackupPage>
    with WidgetsBindingObserver {
  String _id = '', _secret = '';
  bool _importing = false;
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

  Future<void> _importClient() async {
    if (_importing || _service.busy) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _importing = true);
    try {
      final source =
          await (widget.pickClient?.call(context) ??
              DocumentFiles.pickDriveClientText(context: context));
      if (source == null || !mounted) return;
      final client = DriveClientConfiguration.parse(source);
      setState(() {
        _id = client.clientId;
        _secret = client.clientSecret;
      });
      showActionNotice(context, l.backupDriveClientImported);
    } catch (_) {
      if (mounted) {
        showActionNotice(context, l.backupDriveClientImportFailed, error: true);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<DriveBackupService>();
    final canConnect =
        !service.busy &&
        !_importing &&
        _id.trim().isNotEmpty &&
        _secret.trim().isNotEmpty;
    final canDisconnect = !service.busy && !_importing && service.configured;
    return SettingsPageLayout(
      title: Text(service.yandex ? l.backupYandexDisk : l.backupGoogleDrive),
      child: ListView(
        children: [
          SettingsSection(
            key: const ValueKey('settingsGroupClient'),
            title: l.settingsGroupClient,
            children: [
              if (!service.yandex)
                FocusableSettingsTile(
                  title: Text(l.backupDriveClientImport),
                  leading: const Icon(Icons.file_open_outlined),
                  busy: service.busy || _importing,
                  onPressed: service.busy || _importing ? null : _importClient,
                ),
              SizedBox(
                height: 4,
                child: _importing ? const LinearProgressIndicator() : null,
              ),
              FocusableSettingsTile(
                title: Text(l.backupClientId),
                busy: service.busy || _importing,
                valueIcon: Icons.edit_outlined,
                trailing: Text(
                  _id.isEmpty ? l.settingsValueNotSet : _id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                ),
                onPressed: service.busy || _importing
                    ? null
                    : () => _edit(false),
              ),
              FocusableSettingsTile(
                title: Text(l.backupClientSecret),
                busy: service.busy || _importing,
                valueIcon: Icons.edit_outlined,
                trailing: Text(
                  _secret.isEmpty ? l.settingsValueNotSet : '••••••',
                ),
                onPressed: service.busy || _importing
                    ? null
                    : () => _edit(true),
              ),
            ],
          ),
          SettingsSection(
            key: const ValueKey('settingsGroupAccount'),
            title: l.settingsGroupAccount,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        service.configured
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        color: service.configured
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.yandex
                                  ? l.backupYandexConnectionStatus
                                  : l.backupDriveConnectionStatus,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.configured
                                  ? l.backupConfigured
                                  : l.backupNotConfigured,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (service.code.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    service.code,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SettingsReadOnlyValue(
                  label: 'URL',
                  value: service.verificationUrl,
                  textDirection: TextDirection.ltr,
                ),
                Center(
                  child: QrImageView(
                    data: service.verificationUrl,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
              FocusableSettingsTile(
                leading: const Icon(Icons.link),
                title: Text(
                  service.configured
                      ? (service.yandex
                            ? l.backupYandexReconnect
                            : l.backupDriveReconnect)
                      : (service.yandex
                            ? l.backupYandexConnect
                            : l.backupDriveConnect),
                ),
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
                              yandex: service.yandex,
                            );
                            if (message == null) return;
                            showActionNotice(context, message, error: true);
                          }
                        }
                      },
              ),
              SizedBox(
                child: service.busy ? const LinearProgressIndicator() : null,
              ),
              if (service.failed)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    cloudErrorMessage(
                          l,
                          CloudBackupException(
                            service.failureCode ?? 'unknown',
                          ),
                          drive: true,
                          yandex: service.yandex,
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
                        final confirmed = await showLauncherDialog<bool>(
                          context: context,
                          builder: (dialog) => LauncherAlertDialog(
                            title: Text(l.cloudDisconnect),
                            content: Text(l.cloudDisconnectConfirm),
                            actions: [
                              LauncherDialogButton(
                                autofocus: true,
                                isCancel: true,
                                onPressed: () => Navigator.pop(dialog, false),
                                child: Text(l.cancel),
                              ),
                              LauncherDialogButton(
                                primary: true,
                                onPressed: () => Navigator.pop(dialog, true),
                                child: Text(l.cloudDisconnect),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !mounted || service.busy) {
                          return;
                        }
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
            ],
          ),
          SettingsHelp(
            title: l.backupManagement,
            text: service.yandex ? l.backupYandexHelp : l.backupDriveHelp,
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
