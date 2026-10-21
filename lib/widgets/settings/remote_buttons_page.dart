import 'settings_help.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge_result.dart';
import '../../flauncher_channel.dart';
import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import 'adb_permission_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'remote_mappings_page.dart';

/// Remapper menu, access setup and explicit bounded button diagnostics.
class RemoteButtonsPage extends StatefulWidget {
  static const routeName = 'remote_buttons';
  final String section;
  const RemoteButtonsPage({super.key, this.section = 'main'});

  @override
  State<RemoteButtonsPage> createState() => _RemoteButtonsPageState();
}

class _RemoteButtonsPageState extends State<RemoteButtonsPage>
    with WidgetsBindingObserver {
  static const _methods = BridgeChannel('cutelauncher/remote_buttons');
  StreamSubscription<dynamic>? _subscription;
  Map<String, dynamic>? _info;
  bool _busy = false, _failed = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.section == 'diagnostics') {
      _subscription = const EventChannel('cutelauncher/remote_button_events')
          .receiveBroadcastStream()
          .listen(
            _update,
            onError: (Object _) {
              if (mounted) setState(() => _failed = true);
            },
          );
    }
    _call('info');
  }

  void _update(dynamic value) {
    if (!mounted || value is! Map) return;
    setState(() {
      _info = Map<String, dynamic>.from(value);
      _failed = false;
    });
  }

  Future<void> _call(String method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final value = await _methods
          .invokeMapMethod<String, dynamic>(method)
          .timeout(const Duration(seconds: 5));
      if (value == null) throw StateError('Missing button diagnostics');
      _update(value);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Observation continues for at most 120 seconds when an OEM button opens an app.
    // Re-read the bounded native history on return, including its expired status.
    if (state == AppLifecycleState.resumed) _call('info');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Detach the screen; the explicit native session keeps its 120-second deadline.
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _permission() async {
    final l = AppLocalizations.of(context)!;
    await showLauncherDialog<void>(
      context: context,
      builder: (ctx) => LauncherAlertDialog(
        title: Text(l.adbAccessibilitySettings),
        content: Text(l.adbAccessibilityGuide),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    if (mounted) await FLauncherChannel().requestAccessibilityPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final info = _info;
    final active = info?['active'] == true;
    final ready = info?['permission'] == true && info?['connected'] == true;
    final events = (info?['events'] as List? ?? const []).whereType<Map>();
    String state(String name) => info == null
        ? '—'
        : info[name] == true
        ? l.enabled
        : l.disabled;
    return SettingsPageLayout(
      title: Text(
        widget.section == 'access'
            ? l.remoteAccessSettings
            : widget.section == 'diagnostics'
            ? l.remoteButtonsTest
            : l.remoteButtonsTitle,
      ),
      child: ListView(
        children: [
          if (widget.section == 'main') ...[
            RemoteMappingsSwitch(key: ValueKey(_revision)),
            FocusableSettingsTile(
              autofocus: true,
              title: Text(l.remoteAccessSettings),
              trailing: Text(
                info == null
                    ? '—'
                    : info['permission'] == true
                    ? l.granted
                    : l.permissionRequired,
              ),
              leading: const Icon(Icons.accessibility),
              onPressed: () async {
                await Navigator.of(context).push(
                  SettingsRoute(
                    builder: (_) => const RemoteButtonsPage(section: 'access'),
                  ),
                );
                if (mounted) _call('info');
              },
            ),
            FocusableSettingsTile(
              title: Text(l.remoteBindings),
              leading: const Icon(Icons.tune),
              onPressed: () async {
                await Navigator.of(context).push(
                  SettingsRoute(builder: (_) => const RemoteMappingsPage()),
                );
                if (mounted) setState(() => _revision++);
              },
            ),
            FocusableSettingsTile(
              title: Text(l.remoteButtonsTest),
              leading: const Icon(Icons.settings_remote),
              onPressed: () => Navigator.of(context).push(
                SettingsRoute(
                  builder: (_) =>
                      const RemoteButtonsPage(section: 'diagnostics'),
                ),
              ),
            ),
          ],
          if (widget.section == 'access') ...[
            Text(
              '${l.accessibilityPermission}: ${info == null
                  ? '—'
                  : info['permission'] == true
                  ? l.granted
                  : l.permissionRequired}',
            ),
            Text('${l.remoteButtonsService}: ${state('connected')}'),
            FocusableSettingsTile(
              autofocus: true,
              title: Text(l.adbAccessibilitySettings),
              leading: const Icon(Icons.accessibility),
              onPressed: _permission,
            ),
            AdbPermissionTile(
              title: l.adbEnableService,
              action: 'accessibility',
              permissionMethod: 'checkAccessibilityPermission',
              onRefresh: () => _call('info'),
            ),
          ],
          if (widget.section == 'diagnostics') ...[
            FocusableSettingsTile(
              key: const ValueKey('remote-buttons-capture'),
              enabled: !_busy && (active || ready),
              title: Text(active ? l.remoteButtonsStop : l.remoteButtonsStart),
              leading: Icon(
                active ? Icons.stop_circle_outlined : Icons.settings_remote,
              ),
              onPressed: () => _call(active ? 'stop' : 'start'),
            ),
            SettingsHelp(
              text: '${l.remoteButtonsHint}\n${info?['reportPath'] ?? ''}',
            ),
            if (_failed) Text(l.memoryUnavailable),
            const Divider(),
            if (events.isEmpty) Text(l.remoteButtonsEmpty),
            for (final event in events.toList().reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '#${event['id']}  ${event['keyName']} (${event['keyCode']})\n'
                  '${event['action'] == 0
                      ? 'DOWN'
                      : event['action'] == 1
                      ? 'UP'
                      : 'MULTIPLE'}'
                  ' · repeat=${event['repeat']} · ${event['elapsedMs']} ms'
                  ' · scan=${event['scanCode']} · device=${event['deviceId']}'
                  ' · source=${event['source']} · cancelled=${event['cancelled']}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textDirection: TextDirection.ltr,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
