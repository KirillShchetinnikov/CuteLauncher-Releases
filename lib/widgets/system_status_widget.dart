import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_service.dart';
import '../providers/system_status_service.dart';
import 'top_panel_item.dart';
import 'home_skeleton.dart';

class SystemStatusWidget extends StatefulWidget {
  final bool visible, selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;
  const SystemStatusWidget({
    super.key,
    required this.focusNode,
    required this.onPressed,
    this.visible = true,
    this.selected = false,
  });
  @override
  State<SystemStatusWidget> createState() => _SystemStatusWidgetState();
}

class _SystemStatusWidgetState extends State<SystemStatusWidget> {
  SystemStatusService? _service;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SystemStatusService>();
    if (_service != service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    // Defer I/O until after the current frame; Home never waits for a sample.
    _updateVisibility();
  }

  void _updateVisibility() {
    final visible = widget.visible && TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service?.setVisible(this, visible);
    });
  }

  @override
  void didUpdateWidget(SystemStatusWidget oldWidget) {
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
    final state = context.select<SystemStatusService, SystemStatus>(
      (s) => s.state,
    );
    final settings = context.watch<SettingsService>();
    final l = AppLocalizations.of(context)!;
    final ram = ramPercent(state)?.round();
    return Semantics(
      label: l.system,
      child: TopPanelItem(
        focusNode: widget.focusNode,
        selected: widget.selected,
        onPressed: widget.onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined),
            if (settings.systemShowCpu) ...[
              const SizedBox(width: 4),
              HomeSkeletonValue(sample: 'CPU 100%',
                child: Text('CPU ${state.cpu == null ? '—' : '${state.cpu}%'}')),
            ],
            if (settings.systemShowRam) ...[
              const SizedBox(width: 8),
              HomeSkeletonValue(sample: 'RAM 100%',
                child: Text('RAM ${ram == null ? '—' : '$ram%'}')),
            ],
          ],
        ),
      ),
    );
  }
}
