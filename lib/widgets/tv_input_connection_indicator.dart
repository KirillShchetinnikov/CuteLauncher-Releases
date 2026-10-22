import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/tv_input.dart';

/// Connection information is independent of keyboard focus or selected playback.
class TvInputConnectionIndicator extends StatelessWidget {
  final TvInputConnection connection;
  const TvInputConnectionIndicator({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, color, icon) = switch (connection) {
      TvInputConnection.connected => (
        l.inputConnected,
        const Color(0xFF66D99A),
        Icons.circle,
      ),
      TvInputConnection.standby => (
        l.inputStandby,
        const Color(0xFFFFCB70),
        Icons.pause_circle_filled,
      ),
      TvInputConnection.disconnected => (
        l.inputDisconnected,
        Theme.of(context).disabledColor,
        Icons.circle_outlined,
      ),
      TvInputConnection.unknown => (
        l.inputStateUnknown,
        Theme.of(context).disabledColor,
        Icons.help_outline,
      ),
    };
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }
}
