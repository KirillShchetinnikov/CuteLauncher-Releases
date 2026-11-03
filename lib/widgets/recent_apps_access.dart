import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../recent_apps_client.dart';
import 'action_notice.dart';
import 'settings/adb_page.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/settings_route.dart';

/// Access is checked on entry, explicit refresh and return, without polling.
class RecentAppsAccess extends StatefulWidget {
  final bool inSettings;
  final int revision;
  const RecentAppsAccess({
    super.key,
    this.inSettings = false,
    this.revision = 0,
  });

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
  void didUpdateWidget(covariant RecentAppsAccess oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision) _refresh();
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
      if (widget.inSettings && destination == 'adb') {
        await Navigator.of(context).push(
          SettingsRoute(builder: (_) => const AdbPage(section: 'connection')),
        );
      } else if (!await _client.setup(destination)) {
        throw StateError('Settings unavailable');
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

    final statuses = [
      status('adb', l.adbConnectionBlock, _adb, l.inputConnected),
      status('accessibility', l.accessibility, _accessibility, l.granted),
    ];
    if (!widget.inSettings) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final item in statuses) Expanded(child: item)],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: statuses,
    );
  }
}
