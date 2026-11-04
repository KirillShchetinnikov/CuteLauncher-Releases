import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/system_status_service.dart';
import '../theme/interface_style.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/system_widget_settings_page.dart';
import 'side_panel_dialog.dart';

String systemBytes(int? bytes) {
  if (bytes == null) return '—';
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  var value = bytes.toDouble(), unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

class SystemStatusMenu extends StatefulWidget {
  final Rect anchor;
  const SystemStatusMenu({super.key, required this.anchor});
  @override
  State<SystemStatusMenu> createState() => _SystemStatusMenuState();
}

class _SystemStatusMenuState extends State<SystemStatusMenu> {
  final _settingsNode = FocusNode();
  final _contentNode = FocusNode(skipTraversal: true);
  final _scroll = ScrollController();
  bool _settingsOpen = false;
  SystemStatusService? _service;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncScrollFocus);
  }

  void _syncScrollFocus() {
    if (_settingsOpen) return;
    if (_scroll.offset > 0 && _settingsNode.hasFocus) {
      // Keep remote scrolling active after the header leaves the viewport.
      _contentNode.requestFocus();
    } else if (_scroll.offset <= 0 && _contentNode.hasPrimaryFocus) {
      _settingsNode.requestFocus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SystemStatusService>();
    if (_service != service) {
      _service?.setVisible(this, false);
      _service = service;
      service.setVisible(this, true);
    }
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    _settingsNode.dispose();
    _contentNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    _service?.setVisible(this, false);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: SystemWidgetSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    _service?.setVisible(this, true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  KeyEventResult _scrollKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent ||
        !_scroll.hasClients) {
      return KeyEventResult.ignored;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
        ? 60.0
        : event.logicalKey == LogicalKeyboardKey.arrowUp
        ? -60.0
        : 0.0;
    if (delta == 0 || _scroll.position.maxScrollExtent == 0) {
      return KeyEventResult.ignored;
    }
    _scroll.jumpTo(
      (_scroll.offset + delta).clamp(0, _scroll.position.maxScrollExtent),
    );
    return KeyEventResult.handled;
  }

  Widget _value(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 4,
      children: [Text(title), Text(value)],
    ),
  );

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _contentNode,
    onKeyEvent: _scrollKey,
    child: SettingsPanelStyle(
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        final service = context.watch<SystemStatusService>();
        final state = service.state;
        final ram = ramPercent(state);
        final minutes = state.uptimeMinutes;
        final uptime = minutes == null
            ? '—'
            : '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
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
                  width: 480,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsetsDirectional.only(end: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MenuHeader(
                          title: Text(l.system),
                          actions: [
                            MenuHeaderAction(
                              focusNode: _settingsNode,
                              autofocus: true,
                              tooltip: l.systemWidgetSettings,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: _openSettings,
                            ),
                          ],
                        ),
                        const Divider(),
                        _value(
                          'CPU',
                          state.cpu == null
                              ? l.memoryUnavailable
                              : '${state.cpu}%',
                        ),
                        _value(
                          'RAM',
                          state.ramTotal == null || state.ramAvailable == null
                              ? '—'
                              : '${systemBytes(state.ramTotal! - state.ramAvailable!)} / ${systemBytes(state.ramTotal)}',
                        ),
                        if (ram != null) ...[
                          LinearProgressIndicator(value: ram / 100),
                          _value(
                            l.systemAvailable,
                            '${systemBytes(state.ramAvailable)} · ${(100 - ram).round()}%',
                          ),
                        ],
                        _value(
                          l.systemStorage,
                          '${systemBytes(state.storageAvailable)} / ${systemBytes(state.storageTotal)}',
                        ),
                        _value(l.systemUptime, uptime),
                        if (state.temperature != null)
                          _value(
                            l.systemTemperature,
                            '${state.temperature} °C',
                          ),
                        const Divider(),
                        Text(
                          l.systemHistory,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final cpu in [true, false])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SystemHistoryChart(
                              history: service.history,
                              minute:
                                  service.now().millisecondsSinceEpoch ~/ 60000,
                              cpu: cpu,
                            ),
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

class SystemHistoryChart extends StatelessWidget {
  final List<SystemHistoryMinute> history;
  final int minute;
  final bool cpu;
  const SystemHistoryChart({
    super.key,
    required this.history,
    required this.minute,
    required this.cpu,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final graphHeight =
        (MediaQuery.textScalerOf(context).scale(
                  Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16,
                ) *
                4)
            .clamp(88.0, double.infinity);
    final values = history.where(
      (p) =>
          p.minute <= minute &&
          p.minute > minute - 60 &&
          (cpu ? p.cpu : p.ram) != null,
    );
    final latest = values.isEmpty
        ? null
        : (cpu ? values.last.cpu : values.last.ram);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: InterfaceSkin.of(context).surface(
        colors.onSurface.withValues(alpha: .06),
        colors.onSurface,
        borderWidth: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${cpu ? 'CPU' : 'RAM'} · ${latest == null ? l.memoryUnavailable : '${latest.round()}%'}',
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(l.memoryUnavailable),
            )
          else
            Semantics(
              label: '${cpu ? 'CPU' : 'RAM'} 0–100%',
              child: SizedBox(
                height: graphHeight,
                child: Row(
                  children: [
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('100%'), Text('0%')],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomPaint(
                        size: Size(double.infinity, graphHeight),
                        painter: SystemHistoryPainter(
                          history: history,
                          minute: minute,
                          cpu: cpu,
                          color: colors.primary,
                          gridColor: colors.onSurface.withValues(alpha: .2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(l.systemHourAgo), Text(l.systemNow)],
          ),
        ],
      ),
    );
  }
}

class SystemHistoryPainter extends CustomPainter {
  final List<SystemHistoryMinute> history;
  final int minute;
  final bool cpu;
  final Color color, gridColor;
  SystemHistoryPainter({
    required this.history,
    required this.minute,
    required this.cpu,
    required this.color,
    required this.gridColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in [0.0, .5, 1.0]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        grid,
      );
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final peak = Paint()
      ..color = color.withValues(alpha: .35)
      ..strokeWidth = 2;
    SystemHistoryMinute? previous;
    Offset? previousPosition;
    for (final point in history) {
      final age = minute - point.minute;
      final value = cpu ? point.cpu : point.ram;
      if (age < 0 || age > 59 || value == null) {
        previous = null;
        continue;
      }
      final position = Offset(
        size.width * (1 - age / 60),
        size.height * (1 - value / 100),
      );
      final high = cpu ? point.cpuPeak : point.ramPeak;
      if (high != null) {
        canvas.drawLine(
          position,
          Offset(position.dx, size.height * (1 - high / 100)),
          peak,
        );
      }
      if (previous != null &&
          previous.segment == point.segment &&
          previous.minute + 1 == point.minute) {
        canvas.drawLine(previousPosition!, position, line);
      }
      canvas.drawCircle(position, 2, Paint()..color = color);
      previous = point;
      previousPosition = position;
    }
  }

  @override
  bool shouldRepaint(SystemHistoryPainter oldDelegate) => true;
}
