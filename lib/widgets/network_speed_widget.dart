import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/network_speed_service.dart';
import 'top_panel_item.dart';

String networkSpeedLabel(BuildContext context, int? bytes) {
  if (bytes == null) return '—';
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble(), index = 0;
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }
  final number = NumberFormat(
    index == 0 ? '0' : '0.0',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
  return '$number ${AppLocalizations.of(context)!.networkSpeedUnit(units[index])}';
}

class NetworkSpeedWidget extends StatefulWidget {
  final bool visible, selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;
  const NetworkSpeedWidget({
    super.key,
    required this.focusNode,
    required this.onPressed,
    this.visible = true,
    this.selected = false,
  });

  @override
  State<NetworkSpeedWidget> createState() => _NetworkSpeedWidgetState();
}

class _NetworkSpeedWidgetState extends State<NetworkSpeedWidget> {
  NetworkSpeedService? _service;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<NetworkSpeedService>();
    if (_service != service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    _updateVisibility();
  }

  void _updateVisibility() {
    final visible = widget.visible && TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service?.setVisible(this, visible);
    });
  }

  @override
  void didUpdateWidget(NetworkSpeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateVisibility();
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<NetworkSpeedService, NetworkSpeed>(
      (s) => s.state,
    );
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label:
          '${l.networkSpeedTitle}: ${l.trafficReceived} ${networkSpeedLabel(context, state.received)}, '
          '${l.trafficSent} ${networkSpeedLabel(context, state.sent)}',
      child: TopPanelItem(
        focusNode: widget.focusNode,
        selected: widget.selected,
        onPressed: widget.onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Text('↓ ${networkSpeedLabel(context, state.received)}'),
            const SizedBox(width: 8),
            Text('↑ ${networkSpeedLabel(context, state.sent)}'),
          ],
        ),
      ),
    );
  }
}
