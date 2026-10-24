import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class TvPowerPage extends StatefulWidget {
  static const routeName = 'tv_power';
  static const channel = MethodChannel('cutelauncher/tv_power');
  const TvPowerPage({super.key});

  @override
  State<TvPowerPage> createState() => _TvPowerPageState();
}

class _TvPowerPageState extends State<TvPowerPage> {
  bool _busy = false;
  bool _confirming = false;

  Future<void> _run(bool reboot) async {
    if (_busy || _confirming) return;
    _confirming = true;
    final l = AppLocalizations.of(context)!;
    try {
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(reboot ? l.tvPowerReboot : l.tvPowerOff),
          content: Text(reboot ? l.tvPowerRebootConfirm : l.tvPowerOffConfirm),
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
              child: Text(reboot ? l.tvPowerReboot : l.tvPowerOff),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      final sent = await TvPowerPage.channel.invokeMethod<bool>(
        reboot ? 'reboot' : 'sleep',
      );
      if (!mounted) return;
      showActionNotice(
        context,
        sent == true ? l.tvPowerSent : l.tvPowerFailed,
        error: sent != true,
      );
    } catch (_) {
      if (mounted) showActionNotice(context, l.tvPowerFailed, error: true);
    } finally {
      _confirming = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.tvPowerTitle),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.power_settings_new),
            title: Text(l.tvPowerOff),
            onPressed: () => _run(false),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l.tvPowerReboot),
            onPressed: () => _run(true),
          ),
          if (_busy) const LinearProgressIndicator(),
          SettingsHelp(text: l.tvPowerHelp),
        ],
      ),
    );
  }
}
