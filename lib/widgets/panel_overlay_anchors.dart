import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../flauncher_channel.dart';
import '../theme/launcher_style.dart';
import 'top_panel_item.dart';

/// Samples final positions after the toolbar has fitted and placed its children.
class PanelOverlayAnchors extends StatefulWidget {
  const PanelOverlayAnchors({
    super.key,
    required this.widgets,
    this.publishAppearance = false,
    required this.child,
  });

  final Map<String, GlobalKey> widgets;
  final bool publishAppearance;
  final Widget child;

  @override
  State<PanelOverlayAnchors> createState() => _PanelOverlayAnchorsState();
}

class _PanelOverlayAnchorsState extends State<PanelOverlayAnchors> {
  final _last = <String, (int, int, Size)>{};
  bool _queued = false;
  String? _appearance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.publishAppearance) _publishAppearance();
  }

  @override
  void didUpdateWidget(PanelOverlayAnchors oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.publishAppearance && !oldWidget.publishAppearance) {
      _publishAppearance();
    }
  }

  static const _fontAssets = {
    'Medeo Sans': 'medeo-sans.ttf',
    'Medeo Mono': 'medeo-mono.ttf',
    'Medeo Serif': 'medeo-serif.ttf',
    'Google Sans': 'googlesans-400.ttf',
    'Onest': 'onest.ttf',
    'Manrope': 'manrope.ttf',
    'Outfit': 'outfit.ttf',
    'PanelSans': 'sans.ttf',
    'PanelSerif': 'serif.ttf',
    'PanelMono': 'mono.ttf',
    'PanelCondensed': 'condensed.ttf',
  };

  void _publishAppearance() {
    final appearance = topPanelAppearance(context);
    final textStyle = appearance.panelTextStyleFor(
      Localizations.localeOf(context),
    );
    final style = LauncherStyle.of(context);
    final decoration = topPanelItemDecoration(
      context,
      background: appearance.panelItemBackground,
      foreground: textStyle.color,
      radius: style.topButtonRadius,
    );
    final colors = decoration.gradient?.colors;
    final border = decoration.border as Border?;
    final textSize = MediaQuery.textScalerOf(context)
        .scale(appearance.panelTextSize);
    final encoded = jsonEncode({
      'foreground': textStyle.color?.toARGB32(),
      'background': (colors?.first ?? decoration.color)?.toARGB32(),
      'gradientEnd': colors?.last.toARGB32(),
      'border': border?.top.color.toARGB32(),
      'borderWidth': style.topButtonFocusWidth,
      'radius': style.topButtonRadius,
      'textSize': textSize,
      'height': topPanelItemHeight(textSize, style.topButtonFocusWidth),
      'horizontalPadding': topPanelItemPadding.left + style.topButtonFocusWidth,
      'font': _fontAssets[textStyle.fontFamily],
    });
    if (_appearance == encoded) return;
    _appearance = encoded;
    unawaited(_sendAppearance(encoded));
  }

  Future<void> _sendAppearance(String encoded) async {
    try {
      await FLauncherChannel().setOverlayPanelAppearance(encoded);
    } on MissingPluginException {
      // The bridge is available only in Android Home.
    } on PlatformException {
      if (_appearance == encoded) _appearance = null;
    }
  }

  void _scheduleSample() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (mounted) _sample();
    });
  }

  void _sample() {
    final view = View.of(context);
    final size = view.physicalSize;
    for (final entry in widget.widgets.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final point =
          box.localToGlobal(box.size.center(Offset.zero)) *
          view.devicePixelRatio;
      if (!point.isFinite || !(Offset.zero & size).contains(point)) continue;
      final value = (point.dx.round(), point.dy.round(), size);
      if (_last[entry.key] == value) continue;
      _last[entry.key] = value;
      unawaited(_send(entry.key, value));
    }
  }

  Future<void> _send(String id, (int, int, Size) value) async {
    try {
      await FLauncherChannel().setOverlayWidgetCenter(id, value.$1, value.$2);
    } on MissingPluginException {
      // The placement bridge is available only in Android Home.
    } on PlatformException {
      if (_last[id] == value) _last.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    _last.removeWhere((id, _) => !widget.widgets.containsKey(id));
    final enabled = widget.widgets.isNotEmpty;
    if (enabled) _scheduleSample();
    return _SampleOnPaint(
      onPaint: enabled ? _scheduleSample : null,
      child: widget.child,
    );
  }
}

class _SampleOnPaint extends SingleChildRenderObjectWidget {
  const _SampleOnPaint({required this.onPaint, required super.child});

  final VoidCallback? onPaint;

  @override
  _SampleRenderBox createRenderObject(BuildContext context) =>
      _SampleRenderBox(onPaint);

  @override
  void updateRenderObject(BuildContext context, _SampleRenderBox renderObject) {
    renderObject.onPaint = onPaint;
  }
}

class _SampleRenderBox extends RenderProxyBox {
  _SampleRenderBox(this.onPaint);

  VoidCallback? onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onPaint?.call();
  }
}
