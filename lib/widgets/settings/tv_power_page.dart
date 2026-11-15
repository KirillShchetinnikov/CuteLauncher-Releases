import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../tv_power_action.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class TvPowerPage extends StatefulWidget {
  static const routeName = 'tv_power';
  const TvPowerPage({super.key});

  @override
  State<TvPowerPage> createState() => _TvPowerPageState();
}

class _TvPowerPageState extends State<TvPowerPage> {
  bool _busy = false;
  bool _confirming = false;
  Future<void> _run(TvPowerAction action) async {
    if (_busy || _confirming) return;
    _confirming = true;
    try {
      await action.confirmAndSend(
        context,
        onConfirmed: () => setState(() => _busy = true),
      );
    } finally {
      _confirming = false;
      if (mounted && _busy) setState(() => _busy = false);
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
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(l.quickActionsSleep),
            busy: _busy,
            onPressed: () => _run(TvPowerAction.sleep),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.power_settings_new),
            title: Text(l.tvPowerOff),
            busy: _busy,
            onPressed: () => _run(TvPowerAction.shutdown),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l.tvPowerReboot),
            busy: _busy,
            onPressed: () => _run(TvPowerAction.reboot),
          ),
          SizedBox(child: _busy ? const LinearProgressIndicator() : null),
          SettingsHelp(title: l.tvPowerTitle, text: l.tvPowerHelp),
        ],
      ),
    );
  }
}
