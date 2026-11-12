import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../action_notice.dart';
import 'automatic_backup_page.dart';
import 'backup_feature_page.dart';
import 'cloud_backup_page.dart';
import 'drive_backup_page.dart';
import 'local_backup_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_option_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_panel_style.dart';

String backupDestinationLabel(AppLocalizations l, BackupDestination d) =>
    switch (d) {
      BackupDestination.webdav => 'WebDAV / Nextcloud',
      BackupDestination.googleDrive => l.backupGoogleDrive,
      BackupDestination.yandexDisk => l.backupYandexDisk,
      BackupDestination.smb => l.backupSmb,
      BackupDestination.local => l.backupLocal,
    };
String backupAccountLabel(AppLocalizations l, BackupAutomationService s) {
  final ids =
      s.accounts?.ids(
        s.destination == BackupDestination.googleDrive,
        yandex: s.destination == BackupDestination.yandexDisk,
        smb: s.destination == BackupDestination.smb,
      ) ??
      ['default'];
  return '${l.backupAccount} ${ids.indexOf(s.accountId(s.destination)) + 1}';
}

class BackupStoragePage extends StatelessWidget {
  const BackupStoragePage({super.key});
  @override
  Widget build(BuildContext context) => SettingsPageLayout(
    title: Text(AppLocalizations.of(context)!.backupStorage),
    child: const ListViewStorage(),
  );
}

class ListViewStorage extends StatelessWidget {
  const ListViewStorage({super.key});
  @override
  Widget build(BuildContext context) =>
      ListView(children: const [BackupStorageControls()]);
}

class BackupStorageControls extends StatefulWidget {
  const BackupStorageControls({super.key});
  @override
  State<BackupStorageControls> createState() => _BackupStorageControlsState();
}

class _BackupStorageControlsState extends State<BackupStorageControls> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.backupSyncGroupsFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(BackupAutomationService s) async {
    final fullscreen =
        Navigator.of(context) == Navigator.of(context, rootNavigator: true);
    final page = backupServiceScope(s, switch (s.destination) {
      BackupDestination.googleDrive => const DriveBackupPage(),
      BackupDestination.yandexDisk => const DriveBackupPage(),
      BackupDestination.webdav => const CloudBackupPage(),
      BackupDestination.smb => const CloudBackupPage(smb: true),
      BackupDestination.local => const LocalBackupPage(),
    });
    await Navigator.of(context).push(
      SettingsRoute(
        builder: (_) => fullscreen
            ? SettingsPanelStyle(
                builder: (_) => Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: page,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : page,
      ),
    );
    if (s.destination == BackupDestination.googleDrive) {
      await s.drive.refreshAccount();
    }
    if (s.destination == BackupDestination.yandexDisk) {
      await s.yandex.refreshAccount();
    }
    if (s.destination == BackupDestination.smb) await s.smb.refreshAccount();
    if (s.destination == BackupDestination.webdav) {
      await s.webdav.refreshAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<BackupAutomationService>();
    final busy = _busy || s.busy;
    final ids =
        s.accounts?.ids(
          s.destination == BackupDestination.googleDrive,
          yandex: s.destination == BackupDestination.yandexDisk,
          smb: s.destination == BackupDestination.smb,
        ) ??
        ['default'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableSettingsTile(
          title: Text(l.backupStorage),
          trailing: Text(backupDestinationLabel(l, s.destination)),
          busy: busy,
          onPressed: () => _run(() async {
            final selected = await backupChoice(context, l.backupStorage, {
              for (final d in BackupDestination.values)
                d: backupDestinationLabel(l, d),
            }, s.destination);
            if (selected != null) await s.configure(destination: selected);
          }),
        ),
        if (s.destination != BackupDestination.local) ...[
          for (final id in ids)
            SettingsOptionTile(
              title: Text(
                '${l.backupAccount} ${ids.indexOf(id) + 1}${s.accounts?.usedByOther(s.mode.name, s.destination == BackupDestination.googleDrive, id, yandex: s.destination == BackupDestination.yandexDisk, smb: s.destination == BackupDestination.smb) == null ? '' : ' · ${s.mode == BackupMode.backup ? l.backupSyncMode : l.backupSaveMode}'}',
              ),
              selected: s.accountId(s.destination) == id,
              enabled: !busy,
              onPressed: () => _run(() async {
                if (s.accounts != null) await s.selectAccount(id);
              }),
            ),
          if (s.accounts != null)
            FocusableSettingsTile(
              title: Text(l.backupNewAccount),
              busy: busy,
              onPressed: () => _run(() async {
                final id = await s.accounts!.create(
                  s.destination == BackupDestination.googleDrive,
                  yandex: s.destination == BackupDestination.yandexDisk,
                  smb: s.destination == BackupDestination.smb,
                );
                await s.selectAccount(id);
                if (mounted) await _connect(s);
              }),
            ),
        ],
        FocusableSettingsTile(
          title: Text(
            s.destination == BackupDestination.local
                ? l.backupLocal
                : l.backupConnection,
          ),
          trailing: Text(
            s.configured ? l.backupConfigured : l.backupNotConfigured,
          ),
          busy: busy,
          onPressed: () => _run(() => _connect(s)),
        ),
        SettingsHelp(title: l.backupAccount, text: l.backupAccountLocalHelp),
      ],
    );
  }
}
