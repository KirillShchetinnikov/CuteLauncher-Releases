import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../recent_apps_client.dart';
import 'adb_page.dart';
import 'focusable_settings_tile.dart';
import 'remote_buttons_page.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

class RecentAppsPage extends StatefulWidget {
  static const routeName = 'recent_apps_settings';
  const RecentAppsPage({super.key});
  @override
  State<RecentAppsPage> createState() => _RecentAppsPageState();
}

class _RecentAppsPageState extends State<RecentAppsPage>
    with WidgetsBindingObserver {
  final _client = RecentAppsClient();
  String _mode = 'auto';
  bool _busy = true, _failed = false, _loaded = false;
  bool _systemAvailable = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    try {
      final info = await _client.info();
      if (mounted) {
        setState(() {
          _mode = info['mode'] as String;
          _systemAvailable = info['systemAvailable'] == true;
          _loaded = true;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String value) async {
    setState(() => _busy = true);
    try {
      if (!await _client.setMode(value)) throw StateError('Save failed');
      if (mounted) {
        setState(() {
          _mode = value;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final opened = await _client.open();
      if (mounted) setState(() => _failed = !opened);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.recentAppsTitle),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            title: l.recentAppsPanelType,
            value: _mode,
            options: [
              'auto',
              'custom',
              if (_systemAvailable || _mode == 'system') 'system',
            ],
            label: (mode) => switch (mode) {
              'custom' => l.recentAppsCustom,
              'system' => l.recentAppsSystem,
              _ => l.recentAppsAutomatic,
            },
            enabled: _loaded && !_busy,
            onChanged: _save,
          ),
          FocusableSettingsTile(
            title: Text(l.recentAppsOpen),
            leading: const Icon(Icons.recent_actors_outlined),
            enabled:
                _loaded && !_busy && (_mode != 'system' || _systemAvailable),
            onPressed: _open,
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_failed)
            Text(
              l.recentAppsUnavailable,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          SettingsHelp(text: '${l.recentAppsCustom}: ${l.recentAppsHelp}'),
          FocusableSettingsTile(
            title: Text(l.remoteButtonsTitle),
            leading: const Icon(Icons.settings_remote),
            onPressed: () =>
                Navigator.of(context).pushNamed(RemoteButtonsPage.routeName),
          ),
          FocusableSettingsTile(
            title: Text(l.adbConnectionBlock),
            leading: const Icon(Icons.link),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                builder: (_) => const AdbPage(section: 'connection'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
