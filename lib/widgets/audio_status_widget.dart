import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/audio_status_service.dart';
import 'top_panel_item.dart';

/// Information only: no focus node, pointer action, or volume-key handler.
class AudioStatusWidget extends StatefulWidget {
  final bool visible;
  const AudioStatusWidget({super.key, this.visible = true});
  @override
  State<AudioStatusWidget> createState() => _AudioStatusWidgetState();
}

class _AudioStatusWidgetState extends State<AudioStatusWidget> {
  AudioStatusService? _service;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<AudioStatusService?>();
    if (service != _service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    _service?.setVisible(this, widget.visible);
  }

  @override
  void didUpdateWidget(AudioStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _service?.setVisible(this, widget.visible);
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<AudioStatusService?, AudioStatus>(
      (service) => service?.state ?? unknownAudioStatus,
    );
    final l = AppLocalizations.of(context)!;
    final output = switch (state.output) {
      'tv' => l.audioOutputTv,
      'arc' => 'ARC',
      'earc' => 'eARC',
      'hdmi' => 'HDMI',
      'bluetooth' => 'Bluetooth',
      'usb' => 'USB',
      'headphones' => l.audioOutputHeadphones,
      'spdif' => 'S/PDIF',
      'line' => 'AUX',
      'multiple' => l.audioOutputMultiple,
      _ => '—',
    };
    final icon = switch (state.output) {
      'bluetooth' => Icons.bluetooth_audio,
      'arc' || 'earc' || 'spdif' || 'line' => Icons.speaker_group_outlined,
      'hdmi' => Icons.settings_input_hdmi,
      'usb' => Icons.usb,
      'headphones' => Icons.headphones,
      'multiple' => Icons.speaker_group_outlined,
      _ => Icons.tv,
    };
    final volume = state.percent == null ? '—' : '${state.percent}%';
    return Semantics(
      label:
          '${l.audioStatusTitle}: ${state.muted == true ? l.audioMuted : volume}, $output',
      child: ExcludeSemantics(
        child: TopPanelItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.muted == true || state.percent == 0
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
              ),
              if (state.muted != true) ...[
                const SizedBox(width: 4),
                Text(volume),
              ],
              const SizedBox(width: 8),
              Icon(icon),
              const SizedBox(width: 4),
              Text(output),
            ],
          ),
        ),
      ),
    );
  }
}
