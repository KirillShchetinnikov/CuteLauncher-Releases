import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/remote_battery_service.dart';
import '../providers/settings_service.dart';
import '../remote_battery_preferences.dart';
import '../theme/launcher_colors.dart';
import 'launcher_dialog.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/settings_option_tile.dart';
import 'top_panel_item.dart';

class RemoteBatteryWidget extends StatelessWidget {
  final bool visible;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;
  final bool selected;
  const RemoteBatteryWidget({
    super.key,
    this.visible = true,
    this.focusNode,
    this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final (percent, disconnected) = context
        .select<RemoteBatteryService?, (int?, bool)>(
          (service) =>
              (service?.percent, service?.selectedUnavailable ?? false),
        );
    final (
      showPercent,
      colorLowCharge,
      lowThreshold,
    ) = context.select<SettingsService?, (bool, bool, int)>(
      (settings) => (
        settings?.showRemoteBatteryPercent ?? true,
        settings?.remoteBatteryLowColorEnabled ?? true,
        settings?.remoteBatteryLowThreshold ?? remoteBatteryDefaultLowThreshold,
      ),
    );
    Color? lowColor;
    if (colorLowCharge &&
        !disconnected &&
        percent != null &&
        percent < lowThreshold) {
      final background = Color.alphaBlend(
        topPanelAppearance(context).panelItemBackground,
        Theme.of(context).colorScheme.surface,
      );
      final light = LauncherColors.onAccent(background) == Colors.white;
      final warning = light ? const Color(0xffff9d94) : const Color(0xff93000a);
      lowColor = LauncherColors.contrast(warning, background) >= 4.5
          ? warning
          : light
          ? const Color(0xffffefed)
          : const Color(0xff300003);
    }
    final l = AppLocalizations.of(context)!;
    final label = percent == null ? '—' : '$percent%';
    return _RemoteBatteryWatch(
      visible: visible,
      child: Semantics(
        label:
            '${l.remoteBatteryTitle}: ${disconnected ? l.inputDisconnected : label}',
        child: TopPanelItem(
          focusNode: focusNode,
          onPressed: onPressed,
          selected: selected,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (disconnected)
                  const Icon(Icons.battery_std)
                else if (percent == null)
                  const Icon(Icons.battery_unknown)
                else
                  Builder(
                    builder: (context) {
                      final icon = IconTheme.of(context);
                      return CustomPaint(
                        size: Size.square(icon.size ?? 24),
                        painter: _BatteryLevelPainter(
                          percent,
                          lowColor ?? icon.color ?? Colors.white,
                        ),
                      );
                    },
                  ),
                if (disconnected || showPercent) const SizedBox(width: 4),
                if (disconnected)
                  const Icon(Icons.close)
                else if (showPercent)
                  Text(
                    label,
                    style: lowColor == null ? null : TextStyle(color: lowColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryLevelPainter extends CustomPainter {
  final int percent;
  final Color color;

  _BatteryLevelPainter(this.percent, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 2, 4, 3),
        const Radius.circular(.6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(6.5, 4.5, 17.5, 22),
        const Radius.circular(1.6),
      ),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    if (percent > 0) {
      const interior = Rect.fromLTRB(8, 6, 16, 20.5);
      canvas.drawRect(
        Rect.fromLTRB(
          interior.left,
          interior.bottom - interior.height * percent / 100,
          interior.right,
          interior.bottom,
        ),
        paint..style = PaintingStyle.fill,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BatteryLevelPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

class RemoteBatteryDeviceButton extends StatelessWidget {
  final bool autofocus;
  final bool visible;
  const RemoteBatteryDeviceButton({
    super.key,
    this.autofocus = false,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    final battery = context.watch<RemoteBatteryService?>();
    if (battery == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final name = battery.selectedName ?? l.homeAuto;
    return _RemoteBatteryWatch(
      visible: visible && ModalRoute.isCurrentOf(context) != false,
      child: FocusableSettingsTile(
        autofocus: autofocus,
        title: Text(l.remoteBatteryDevice),
        trailing: Text(
          battery.selectedUnavailable ? '$name · ${l.inputDisconnected}' : name,
        ),
        onPressed: () => showLauncherDialog<void>(
          context: context,
          builder: (_) => LauncherAlertDialog(
            title: Text(l.remoteBatteryDevice),
            content: const SizedBox(
              width: 400,
              child: _RemoteBatteryWatch(child: _RemoteBatteryChoices()),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteBatteryChoices extends StatefulWidget {
  const _RemoteBatteryChoices();

  @override
  State<_RemoteBatteryChoices> createState() => _RemoteBatteryChoicesState();
}

class _RemoteBatteryChoicesState extends State<_RemoteBatteryChoices> {
  bool _saving = false;

  Future<void> _select(
    RemoteBatteryService battery,
    RemoteBatteryDevice? device,
  ) async {
    if (_saving) return;
    _saving = true;
    final saved = await battery.selectDevice(device);
    _saving = false;
    if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.remoteBatterySelectionFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final battery = context.watch<RemoteBatteryService?>();
    if (battery == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        SettingsOptionTile(
          title: Text(l.homeAuto),
          selected: battery.selectedId == null,
          autofocus: true,
          onPressed: () => _select(battery, null),
        ),
        for (final device in battery.devices)
          SettingsOptionTile(
            key: ValueKey(device.id),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name),
                if (device.address case final address?)
                  Text(
                    address,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            selected: battery.selectedId == device.id,
            onPressed: () => _select(battery, device),
          ),
      ],
    );
  }
}

class _RemoteBatteryWatch extends StatefulWidget {
  final bool visible;
  final Widget child;
  const _RemoteBatteryWatch({this.visible = true, required this.child});

  @override
  State<_RemoteBatteryWatch> createState() => _RemoteBatteryWatchState();
}

class _RemoteBatteryWatchState extends State<_RemoteBatteryWatch> {
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
  void didUpdateWidget(_RemoteBatteryWatch oldWidget) {
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
  Widget build(BuildContext context) => widget.child;
}
