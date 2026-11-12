import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_read_only_value.dart';
import 'settings_text_tile.dart';

class SyncProtectionPage extends StatefulWidget {
  const SyncProtectionPage({super.key});
  @override
  State<SyncProtectionPage> createState() => _SyncProtectionPageState();
}

class _SyncProtectionPageState extends State<SyncProtectionPage>
    with WidgetsBindingObserver {
  String _password = '', _confirmation = '';
  bool _busy = true, _configured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final configured = await context
            .read<BackupAutomationService>()
            .protection
            .configured();
        if (mounted) setState(() => _configured = configured);
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
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() {
        _password = '';
        _confirmation = '';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password = '';
    _confirmation = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<BackupAutomationService>();
    return SettingsPageLayout(
      title: Text(l.backupPassword),
      child: ListView(
        children: [
          SettingsReadOnlyValue(
            label: l.backupPassword,
            value: _configured ? l.backupConfigured : l.backupNotConfigured,
          ),
          SettingsTextTile(
            title: l.backupPassword,
            value: _password,
            obscureText: true,
            maxLength: 1024,
            enabled: !_busy && !s.busy,
            onChanged: (v) => setState(() => _password = v),
          ),
          SettingsTextTile(
            title: l.backupPasswordRepeat,
            value: _confirmation,
            obscureText: true,
            maxLength: 1024,
            enabled: !_busy && !s.busy,
            onChanged: (v) => setState(() => _confirmation = v),
          ),
          FocusableSettingsTile(
            title: Text(l.save),
            busy: _busy || s.busy,
            onPressed: () async {
              if (_password != _confirmation) {
                showActionNotice(
                  context,
                  l.backupPasswordMismatch,
                  error: true,
                );
                return;
              }
              setState(() => _busy = true);
              try {
                await s.setPassword(_password);
                if (mounted) {
                  setState(() {
                    _configured = _password.isNotEmpty;
                    _password = '';
                    _confirmation = '';
                  });
                }
              } catch (_) {
                if (context.mounted) {
                  showActionNotice(
                    context,
                    l.backupSyncGroupsFailed,
                    error: true,
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
          SettingsHelp(
            title: l.backupPassword,
            text: l.backupPasswordOptionalHelp,
          ),
        ],
      ),
    );
  }
}
