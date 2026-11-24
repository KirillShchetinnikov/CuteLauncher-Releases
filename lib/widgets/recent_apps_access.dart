import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../recent_apps_client.dart';
import 'action_notice.dart';
import 'settings/access_settings_links.dart';
import 'settings/focusable_settings_tile.dart';

/// Access is checked on entry and return to settings, without polling.
class RecentAppsAccess extends StatefulWidget {
  const RecentAppsAccess({super.key});

  @override
  State<RecentAppsAccess> createState() => _RecentAppsAccessState();
}

class _RecentAppsAccessState extends State<RecentAppsAccess>
    with WidgetsBindingObserver {
  final _client = RecentAppsClient();
  bool? _adb, _accessibility;
  bool _checking = false, _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final access = await _client.access();
      if (!mounted) return;
      setState(() {
        _adb = access['adb'] as bool?;
        _accessibility = access['accessibility'] as bool?;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _adb = null;
          _accessibility = null;
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _setup(String destination) async {
    if (_opening || _checking) return;
    _opening = true;
    try {
      if (destination == 'adb') {
        await AdbConnectionLink.open(context);
      } else {
        await AccessibilitySettingsLink.open(context);
      }
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.recentAppsUnavailable,
          error: true,
        );
      }
    } finally {
      _opening = false;
      if (mounted) await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget status(
      String destination,
      String label,
      bool? value,
      String granted,
    ) {
      final text = _checking
          ? l.adbPermissionChecking
          : value == null
          ? l.memoryUnavailable
          : value
          ? granted
          : destination == 'adb'
          ? l.inputDisconnected
          : l.compatibilityNotGranted;
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
      if (value != true) {
        return FocusableSettingsTile(
          key: ValueKey('recent-access-$destination'),
          dense: true,
          title: title,
          leading: Icon(
            destination == 'adb' ? Icons.link : Icons.accessibility_new,
          ),
          onPressed: _checking ? null : () => _setup(destination),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: title,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status('adb', l.adbConnectionBlock, _adb, l.inputConnected),
        status('accessibility', l.accessibility, _accessibility, l.granted),
      ],
    );
  }
}
