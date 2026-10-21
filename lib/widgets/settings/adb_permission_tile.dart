import 'adb_action_confirmation.dart';

import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'adb_page.dart';
import 'adb_notice.dart';
import 'focusable_settings_tile.dart';

/// Permission actions use native connection preferences and verify actual access.
class AdbPermissionTile extends StatefulWidget {
  final String title;
  final String action;
  final String permissionMethod;
  final Future<void> Function()? onRefresh;
  const AdbPermissionTile({
    super.key,
    required this.title,
    required this.action,
    required this.permissionMethod,
    this.onRefresh,
  });
  @override
  State<AdbPermissionTile> createState() => _AdbPermissionTileState();
}

class _AdbPermissionTileState extends State<AdbPermissionTile>
    with WidgetsBindingObserver {
  static const _adb = BridgeChannel('cutelauncher/adb');
  static const _platform = BridgeChannel('me.efesser.flauncher/method');
  bool _busy = true;
  bool _granted = false;
  bool _supported = false;
  String _connection = 'unknown';
  String? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  Future<bool> _permission() async {
    try {
      return await _platform.invokeMethod<bool>(widget.permissionMethod) ==
          true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _connectionInfo() async {
    _supported = false;
    try {
      final info = await _adb.invokeMapMethod<String, dynamic>('info');
      if (info == null || info['port'] is! int) {
        return null;
      }
      _supported =
          (info['compatibility'] as Map?)?['actions'] is Map &&
          ((info['compatibility'] as Map)['actions'] as Map)[widget.action] ==
              true;
      return {'port': info['port'], 'tls': false};
    } catch (_) {
      return null;
    }
  }

  Future<String> _check(Map<String, dynamic>? info) async {
    if (info == null) return 'unavailable';
    try {
      final result = await _adb.invokeMapMethod<String, dynamic>('action', {
        ...info,
        'action': 'check',
      });
      return result?['status'] as String? ?? 'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _busy = true);
    final granted = await _permission();
    final info = await _connectionInfo();
    final connection = granted || !_supported ? 'unknown' : await _check(info);
    if (mounted) {
      setState(() {
        _granted = granted;
        _connection = connection;
        _busy = false;
      });
    }
  }

  Future<void> _activate() async {
    if (_busy || !_supported) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      if (await _permission()) {
        if (mounted) setState(() => _granted = true);
        return;
      }
      final info = await _connectionInfo();
      if (!_supported) return;
      final connection = await _check(info);
      if (!mounted) return;
      setState(() {
        _granted = false;
        _connection = connection;
      });
      if (connection != 'ready') {
        await Navigator.of(context).pushNamed(AdbPage.routeName);
        if (mounted) {
          await widget.onRefresh?.call();
          if (mounted) await _refresh();
        }
        return;
      }
      final plan = await _adb.invokeMapMethod<String, dynamic>('action', {
        ...info!,
        'action': 'preview',
        'operation': widget.action,
      });
      if (!mounted) return;
      if (plan?['status'] != 'ready' || plan?['commands'] is! List) {
        setState(() {
          _result = plan?['status'] as String? ?? 'unavailable';
          _connection = 'unavailable';
        });
        return;
      }
      final commands = (plan!['commands'] as List).cast<String>();
      if (!await confirmAdbAction(
            context,
            widget.title,
            widget.action,
            commands,
          ) ||
          !mounted) {
        return;
      }
      final result = await _adb.invokeMapMethod<String, dynamic>('action', {
        ...info,
        'action': widget.action,
        'commands': commands,
      });
      if (!mounted) return;
      await widget.onRefresh?.call();
      final granted = await _permission();
      if (!mounted) return;
      final status = result?['status'] as String? ?? 'unavailable';
      setState(() {
        _granted = granted;
        _result = granted
            ? 'success'
            : status == 'success'
            ? 'denied'
            : status;
        if (status == 'authorization' ||
            status == 'unavailable' ||
            status == 'changed') {
          _connection = status;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _connection = 'unavailable';
          _result = 'unavailable';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_result != null) showAdbNotice(context, _result, title: widget.title);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final status = _busy
        ? l.adbPermissionChecking
        : _granted
        ? l.granted
        : !_supported
        ? l.adbUnsupported
        : _connection == 'ready'
        ? l.adbPermissionConnected
        : _connection == 'authorization'
        ? l.adbAuthorization
        : l.adbPermissionDisconnected;
    return FocusableSettingsTile(
      leading: Icon(_granted ? Icons.check_circle : Icons.link),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
          if (_result != null && !_granted)
            Text(switch (_result) {
              'unsupported' => l.adbUnsupported,
              'denied' => l.adbDenied,
              'authorization' => l.adbAuthorization,
              'invalid' => l.adbInvalid,
              'changed' => l.adbChanged,
              'noRecovery' => l.adbNoRecovery,
              _ => l.adbUnavailable,
            }, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      onPressed: _busy || !_supported || _granted ? null : _activate,
    );
  }
}
