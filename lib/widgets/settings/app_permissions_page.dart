import 'package:flutter/material.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'adb_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';
import 'settings_read_only_value.dart';
import 'settings_route.dart';

/// A service is the consent boundary, including when an app exposes several services.
class AppPermissionsPage extends StatefulWidget {
  final Map<String, dynamic>? service;
  const AppPermissionsPage({super.key, this.service});
  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage>
    with WidgetsBindingObserver {
  static const channel = BridgeChannel('cutelauncher/app_permissions');
  List<Map<String, dynamic>>? _services;
  Map<String, dynamic>? _service;
  bool _busy = false, _failed = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
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

  Future<Map<String, dynamic>> _request(
    String method, [
    Map<String, Object?> extra = const {},
  ]) async {
    final response = await channel.invokeMapMethod<String, dynamic>(method, {
      if (_service != null) 'component': _service!['component'],
      ...extra,
    });
    if (response == null || response['status'] != 'success') {
      throw StateError('App permission operation failed');
    }
    if (mounted) {
      setState(() {
        if (response['service'] is Map) {
          _service = Map<String, dynamic>.from(response['service'] as Map);
        }
        if (response['services'] is List) {
          _services = (response['services'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      });
    }
    if (mounted &&
        const {'apply', 'configure', 'reconnect', 'disable'}.contains(method)) {
      return _request('inspect');
    }
    return response;
  }

  Future<void> _work(Future<void> Function() work) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await work();
    } catch (_) {
      if (mounted) {
        // A failed disable may still have successfully cancelled recovery.
        try {
          final response = await channel.invokeMapMethod<String, dynamic>(
            'list',
          );
          if (mounted && _service != null && response?['services'] is List) {
            for (final row
                in (response!['services'] as List).whereType<Map>()) {
              if (row['component'] == _service!['component']) {
                setState(() => _service = Map<String, dynamic>.from(row));
              }
            }
          }
        } catch (_) {
          /* Keep the last known data and expose the failure. */
        }
        if (mounted) setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _work(() async {
    await _request(_service == null ? 'list' : 'inspect');
  });

  Future<void> _grant() => _work(() async {
    final plan = await _request('preview');
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final accepted = await showLauncherDialog<bool>(
      context: context,
      builder: (ctx) => LauncherAlertDialog(
        title: Text(_service!['name'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.appPermissionsConfirm),
              const SizedBox(height: 12),
              Text(
                '${l.appPermissionsRestore}: ${_service!['restore'] == true ? l.enabled : l.disabled}',
              ),
              if ((plan['commands'] as List? ?? []).isNotEmpty)
                SettingsHelp(
                  title: l.dialogCommandDetails,
                  text: (plan['commands'] as List)
                      .map((e) => 'adb shell $e')
                      .join('\n'),
                ),
            ],
          ),
        ),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            isCancel: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            primary: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.dialogApply),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await _request('apply', {'token': plan['token']});
    }
  });

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(SettingsRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  String _result(
    AppLocalizations l,
    Map<String, dynamic> row,
  ) => switch (row['result']) {
    'identity_changed' => l.appPermissionsIdentity,
    'retry' || 'pending' => l.appPermissionsRetry,
    'success' || 'restored' => l.actionCompleted,
    _ =>
      row['managed'] == true
          ? '${l.appPermissionsRestore}: ${row['restore'] == true ? l.enabled : l.disabled}'
          : l.appPermissionsPending,
  };

  String _mode(AppLocalizations l, String op) {
    final value = (_service?['modes'] as Map?)?[op];
    return switch (value) {
      'unsupported' => l.adbUnsupported,
      'allow' => l.granted,
      'default' when op == 'ACCESS_RESTRICTED_SETTINGS' => l.granted,
      'ignore' ||
      'deny' ||
      'default' ||
      'foreground' => l.compatibilityNotGranted,
      _ => l.compatibilityUnknown,
    };
  }

  String _accessMode(AppLocalizations l) {
    final modes = _service?['modes'] as Map? ?? {};
    final supported = [
      'ACCESS_RESTRICTED_SETTINGS',
      'BIND_ACCESSIBILITY_SERVICE',
    ].where((op) => modes[op] != 'unsupported').toList();
    if (supported.isEmpty) return l.adbUnsupported;
    if (supported.any((op) => modes[op] == null || modes[op] == 'unknown')) {
      return l.compatibilityUnknown;
    }
    return supported.every(
          (op) =>
              modes[op] == 'allow' ||
              (op == 'ACCESS_RESTRICTED_SETTINGS' && modes[op] == 'default'),
        )
        ? l.granted
        : l.compatibilityNotGranted;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = _service;
    return SettingsPageLayout(
      title: Text(service?['name'] as String? ?? l.appPermissionsTitle),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (service == null) ...[
            FocusableSettingsTile(
              title: Text(l.adbConnectionBlock),
              leading: const Icon(Icons.link),
              busy: _busy,
              onPressed: () => _open(const AdbPage(section: 'connection')),
            ),
            FocusableSettingsTile(
              title: Text(l.remoteButtonsRefresh),
              leading: const Icon(Icons.refresh),
              busy: _busy,
              onPressed: _load,
            ),
          ],
          if (_failed)
            SettingsMessage(
              text: l.appPermissionsError,
              kind: SettingsMessageKind.error,
            ),
          if (service == null) ...[
            if (_services == null && !_failed) const LinearProgressIndicator(),
            if (_services?.isEmpty == true)
              SettingsEmptyState(text: l.appPermissionsEmpty, icon: Icons.apps),
            for (final row in _services ?? <Map<String, dynamic>>[])
              FocusableSettingsTile(
                key: ValueKey(row['component']),
                leading: const Icon(Icons.apps),
                busy: _busy,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row['name'] as String),
                    Text(
                      row['service'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      row['managed'] == true && row['restore'] == true
                          ? '${l.appPermissionsRestore}: ${l.enabled}'
                          : '${l.compatibilityAccessibility}: ${row['enabled'] == true ? l.enabled : l.disabled}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onPressed: () => _open(AppPermissionsPage(service: row)),
              ),
          ] else ...[
            SettingsReadOnlyValue(
              label: l.compatibilityAccessibility,
              value:
                  '${service['service']} · ${service['enabled'] == true ? l.enabled : l.disabled}',
              wrapLines: true,
            ),
            SettingsReadOnlyValue(
              label: l.accessibilityPermission,
              value: _accessMode(l),
              wrapLines: true,
            ),
            SettingsReadOnlyValue(
              label: l.appPermissionsAutoStart,
              value: _mode(l, 'AUTO_START'),
              wrapLines: true,
            ),
            SettingsReadOnlyValue(
              label: l.appPermissionsBackground,
              value: _mode(l, 'RUN_ANY_IN_BACKGROUND'),
              wrapLines: true,
            ),
            // Keep action keys and focus stops stable after granting/revoking.
            FocusableSettingsTile(
              key: const ValueKey('app-permissions-grant'),
              title: Text(l.appPermissionsGrant),
              leading: const Icon(Icons.verified_user_outlined),
              busy: _busy,
              onPressed: _grant,
            ),
            RoundedSwitchListTile(
              title: Text(l.appPermissionsRestore),
              value: service['restore'] == true,
              busy: _busy,
              onChanged: (value) => _work(() async {
                await _request('configure', {'restore': value});
              }),
            ),
            SettingsMessage(text: _result(l, service)),
            FocusableSettingsTile(
              title: Text(l.appPermissionsReconnect),
              leading: const Icon(Icons.refresh),
              busy: _busy,
              enabled: service['enabled'] == true,
              onPressed: () => _work(() async {
                await _request('reconnect');
              }),
            ),
            FocusableSettingsTile(
              title: Text(l.appPermissionsDisable),
              leading: const Icon(Icons.power_settings_new),
              busy: _busy,
              enabled: service['enabled'] == true || service['managed'] == true,
              onPressed: () => _work(() async {
                await _request('disable');
              }),
            ),
          ],
          SettingsHelp(text: l.appPermissionsHelp),
        ],
      ),
    );
  }
}
