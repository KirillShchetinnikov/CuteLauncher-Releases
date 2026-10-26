import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/network_service.dart';
import '../theme/interface_style.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/traffic_settings_page.dart';
import 'side_panel_dialog.dart';

class TrafficUsageMenu extends StatefulWidget {
  final Rect anchor;
  const TrafficUsageMenu({super.key, required this.anchor});
  @override
  State<TrafficUsageMenu> createState() => _TrafficUsageMenuState();
}

class _TrafficUsageMenuState extends State<TrafficUsageMenu>
    with WidgetsBindingObserver {
  final _settingsNode = FocusNode();
  final _scrollController = ScrollController();
  bool _settingsOpen = false;
  NetworkService? _network;
  static const _periods = ['daily', 'weekly', 'monthly'];
  Map<String, Future<Map<String, dynamic>>> _snapshots = {};

  void _reload() {
    _snapshots = {
      for (final period in _periods) period: _network!.getTrafficUsage(period),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final network = context.watch<NetworkService>();
    if (_network != network) {
      _network = network;
      _reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _network != null) {
      setState(_reload);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: TrafficSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() {
      _settingsOpen = false;
      _reload();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  String _bytes(Object? value) {
    if (value is! int || value < 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'];
    var number = value.toDouble(), unit = 0;
    while (number >= 1024 && unit < units.length - 1) {
      number /= 1024;
      unit++;
    }
    return '${number.toStringAsFixed(unit == 0 ? 0 : 2)} ${units[unit]}';
  }

  Widget _periodCard(BuildContext context, AppLocalizations l, String period) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final skin = InterfaceSkin.of(context);
    return Container(
      key: ValueKey('traffic_$period'),
      padding: const EdgeInsets.all(12),
      decoration: skin.surface(
        colors.onSurface.withValues(alpha: .06),
        colors.onSurface,
        borderWidth: 1,
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey((_network, period)),
        future: _snapshots[period],
        builder: (context, snapshot) {
          final data = snapshot.data ?? const <String, dynamic>{};
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    trafficPeriodLabel(l, period),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError)
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l.trafficTotal, style: theme.textTheme.bodySmall),
                        Text(
                          _bytes(data['totalBytes']),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (snapshot.hasError)
                Text(l.networkReadFailed)
              else ...[
                const Divider(height: 1),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final received = _transfer(
                      context,
                      Icons.download_outlined,
                      l.trafficReceived,
                      _bytes(data['rxBytes']),
                    );
                    final sent = _transfer(
                      context,
                      Icons.upload_outlined,
                      l.trafficSent,
                      _bytes(data['txBytes']),
                    );
                    if (constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(16) > 22) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [received, const SizedBox(height: 8), sent],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: received),
                        const SizedBox(width: 12),
                        Expanded(child: sent),
                      ],
                    );
                  },
                ),
                if (data['totalBytes'] is! int ||
                    (data['totalBytes'] as int) < 0) ...[
                  const SizedBox(height: 4),
                  Text(l.networkUnavailable),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _transfer(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          ],
        ),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
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
    child: SettingsPanelStyle(
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return ExcludeFocus(
          excluding: _settingsOpen,
          child: Offstage(
            offstage: _settingsOpen,
            child: Stack(
              children: [
                const Positioned.fill(child: LauncherPanelBackdrop()),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                SidePanelDialog(
                  anchor: widget.anchor,
                  width: 440,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MenuHeader(
                          title: Text(l.trafficTitle),
                          actions: [
                            MenuHeaderAction(
                              focusNode: _settingsNode,
                              autofocus: true,
                              tooltip: l.trafficSettings,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: _openSettings,
                            ),
                          ],
                        ),
                        const Divider(),
                        for (final period in _periods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _periodCard(context, l, period),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
