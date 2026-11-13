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
    final settings = context.watch<SettingsService>();
    final showCpu = settings.systemShowCpu;
    final showTemperature = settings.systemShowTemperature;
    final showRam = settings.systemShowRam;
    final (cpu, temperature, ram, temperaturePending) = context.select<SystemStatusService,
        (int?, int?, int?, bool)>((s) => (
      showCpu ? s.state.cpu : null,
      showTemperature ? s.state.temperature : null,
      showRam ? ramPercent(s.state)?.round() : null,
      showTemperature && !s.initialized,
    ));
    final l = AppLocalizations.of(context)!;
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
            if (showCpu) ...[
              const SizedBox(width: 4),
              HomeSkeletonValue(sample: 'CPU 100%',
                child: Text('CPU ${cpu == null ? '—' : '$cpu%'}')),
            ],
            if (temperature != null || temperaturePending) ...[
              const SizedBox(width: 4),
              Semantics(
                label: l.systemTemperature,
                child: HomeSkeletonValue(
                  sample: '100 °C',
                  child: Text(temperature == null ? '—' : '$temperature °C'),
                ),
              ),
            ],
            if (showRam) ...[
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
