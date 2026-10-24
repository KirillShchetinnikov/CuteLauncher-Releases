import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/network_service.dart';
import '../l10n/app_localizations.dart';
import 'launcher_dialog.dart';
import 'menu_header_action.dart';
import 'side_panel_dialog.dart';
import 'settings/settings_panel_style.dart';

/// Owns polling only for the lifetime of the visible network summary.
class NetworkSummaryDialog extends StatefulWidget {
  final NetworkService service;
  final Rect anchor;
  const NetworkSummaryDialog({
    super.key,
    required this.service,
    required this.anchor,
  });

  @override
  State<NetworkSummaryDialog> createState() => _NetworkSummaryDialogState();
}

class _NetworkSummaryDialogState extends State<NetworkSummaryDialog>
    with WidgetsBindingObserver {
  Timer? _timer;
  final _scrollController = ScrollController();
  Map<String, dynamic>? _snapshot;
  double? _rx, _tx;
  bool _busy = false, _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    _generation++;
    _busy = false;
    _snapshot = null;
    _rx = _tx = null;
    if (state == AppLifecycleState.resumed) _start();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    _busy = true;
    final generation = _generation;
    try {
      final next = await widget.service.getSummary();
      if (!mounted || generation != _generation) return;
      final previous = _snapshot;
      double? rate(String key) {
        final before = previous?[key] as int?;
        final after = next[key] as int?;
        final elapsed =
            (next['elapsedMs'] as int? ?? 0) -
            (previous?['elapsedMs'] as int? ?? 0);
        if (before == null ||
            after == null ||
            before < 0 ||
            after < before ||
            elapsed <= 0 ||
            previous?['networkType'] != next['networkType']) {
          return null;
        }
        return (after - before) / elapsed * 1000 / 1024;
      }

      setState(() {
        _rx = rate('rxBytes');
        _tx = rate('txBytes');
        _snapshot = next;
        _failed = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _failed = true;
          _snapshot = null;
          _rx = _tx = null;
        });
      }
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: (_, event) {
      if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
          !_scrollController.hasClients) {
        return KeyEventResult.ignored;
      }
      final direction = event.logicalKey == LogicalKeyboardKey.arrowDown
          ? 1
          : event.logicalKey == LogicalKeyboardKey.arrowUp
          ? -1
          : 0;
      final position = _scrollController.position;
      if (direction == 0 || position.maxScrollExtent == 0) {
        return KeyEventResult.ignored;
      }
      _scrollController.jumpTo(
        (position.pixels + direction * 60).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      return KeyEventResult.handled;
    },
    child: SettingsPanelStyle(builder: _buildPanel),
  );

  Widget _buildPanel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = _snapshot;
    final type = data?['networkType'];
    final connected = type is int && type >= 0 && type < 4;
    final internet = data?['internetAccess'] == true;
    final connection = switch (type) {
      0 => l.networkMobile,
      1 => 'Wi-Fi',
      2 => 'VPN',
      3 => 'Ethernet',
      _ => l.networkDisconnected,
    };
    final icon = switch (type) {
      0 => Icons.cell_tower,
      1 => Icons.wifi,
      2 => Icons.vpn_key,
      3 => Icons.lan_outlined,
      _ => Icons.link_off,
    };
    final metrics = <Widget>[
      if (type == 1) ...[
        _metric(
          context,
          Icons.wifi,
          l.networkSignal,
          data?['rssi'] == null ? l.networkUnavailable : "${data!['rssi']} dBm",
        ),
        _metric(
          context,
          Icons.speed,
          l.networkLinkSpeed,
          data?['linkSpeed'] == null
              ? l.networkUnavailable
              : "${data!['linkSpeed']} ${l.networkMbps}",
        ),
        if (data?['frequency'] != null)
          _metric(
            context,
            Icons.router_outlined,
            l.networkFrequency,
            "${data!['frequency']} MHz",
          ),
      ],
    ];
    return Stack(
      children: [
        const Positioned.fill(child: LauncherPanelBackdrop()),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        SidePanelDialog(
          anchor: widget.anchor,
          width: 380,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.networkSummary,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      MenuHeaderAction(
                        autofocus: true,
                        tooltip: l.networkSystemSettings,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: widget.service.openWifiSettings,
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.networkReadFailed),
                    )
                  else if (data == null)
                    const LinearProgressIndicator()
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: .08,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type == 1
                                      ? data['ssid'] as String? ?? 'Wi-Fi'
                                      : connection,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  !connected
                                      ? l.networkDisconnected
                                      : internet
                                      ? l.networkConnected
                                      : l.networkOffline,
                                ),
                              ],
                            ),
                          ),
                          if (data['vpnActive'] == true)
                            const Padding(
                              padding: EdgeInsetsDirectional.only(start: 8),
                              child: Tooltip(
                                message: 'VPN',
                                child: Icon(Icons.vpn_key_outlined),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (metrics.isNotEmpty) _grid(context, metrics),
                    const SizedBox(height: 12),
                    Text(
                      l.networkTrafficRate,
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    _grid(context, [
                      _metric(
                        context,
                        Icons.south,
                        l.networkReceive,
                        _rx == null
                            ? '—'
                            : '${_rx!.toStringAsFixed(1)} ${l.networkKbps}',
                      ),
                      _metric(
                        context,
                        Icons.north,
                        l.networkSend,
                        _tx == null
                            ? '—'
                            : '${_tx!.toStringAsFixed(1)} ${l.networkKbps}',
                      ),
                    ]),
                    if ((data['addresses'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('IP', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(data['addresses'] as String),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns =
          constraints.maxWidth >= 280 &&
          MediaQuery.textScalerOf(context).scale(16) <= 22;
      if (!twoColumns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        );
      }
      return Column(
        children: [
          for (var i = 0; i < children.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );

  Widget _metric(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
