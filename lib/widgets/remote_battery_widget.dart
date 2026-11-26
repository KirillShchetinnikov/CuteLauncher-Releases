import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/remote_battery_service.dart';
import 'top_panel_item.dart';

class RemoteBatteryWidget extends StatefulWidget {
  final bool visible;
  const RemoteBatteryWidget({super.key, this.visible = true});

  @override
  State<RemoteBatteryWidget> createState() => _RemoteBatteryWidgetState();
}

class _RemoteBatteryWidgetState extends State<RemoteBatteryWidget> {
  RemoteBatteryService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<RemoteBatteryService?>();
    if (service != _service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    _service?.setVisible(this, widget.visible);
  }

  @override
  void didUpdateWidget(RemoteBatteryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _service?.setVisible(this, widget.visible);
    }
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = context.select<RemoteBatteryService?, int?>(
      (service) => service?.percent,
    );
    final title = AppLocalizations.of(context)!.remoteBatteryTitle;
    final label = percent == null ? '—' : '$percent%';
    return Semantics(
      label: '$title: $label',
      child: ExcludeSemantics(
        child: TopPanelItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(percent == null ? Icons.battery_unknown : Icons.battery_std),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
