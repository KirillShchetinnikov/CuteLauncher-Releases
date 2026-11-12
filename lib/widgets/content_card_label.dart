import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scrolls overflowing labels inside their original text bounds.
class ContentCardLabel extends StatelessWidget {
  const ContentCardLabel(
    this.text, {
    super.key,
    required this.scroll,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.subtitle,
    this.subtitleStyle,
  });

  final String text;
  final bool scroll;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final String? subtitle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
    final labels = [
      label,
      if (subtitle case final text?)
        Text(
          text,
          style: subtitleStyle,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ];
    if (!scroll ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      return _stackLabels(labels);
    }
    return _FocusedLabels(labels: labels);
  }
}

Widget _stackLabels(List<Widget> labels) => labels.length == 1
    ? labels.single
    : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: labels,
      );

class _FocusedLabels extends StatefulWidget {
  const _FocusedLabels({required this.labels});

  final List<Text> labels;

  @override
  State<_FocusedLabels> createState() => _FocusedLabelsState();
}

class _FocusedLabelsState extends State<_FocusedLabels>
    with WidgetsBindingObserver {
  static const _focusDelay = Duration(milliseconds: 800);
  Timer? _delay;
  bool _foreground = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    if (_foreground) _startAfterDelay();
  }

  void _startAfterDelay() {
    _delay?.cancel();
    _delay = Timer(_focusDelay, () => setState(() => _ready = true));
  }

  @override
  void didUpdateWidget(_FocusedLabels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_foreground &&
        (oldWidget.labels.first.data != widget.labels.first.data ||
            oldWidget.labels.last.data != widget.labels.last.data ||
            oldWidget.labels.length != widget.labels.length)) {
      _ready = false;
      _startAfterDelay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    _delay?.cancel();
    if (foreground) _startAfterDelay();
    setState(() => _ready = false);
  }

  @override
  void dispose() {
    _delay?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    // Leave rapid focus changes on the ordinary text layout path.
    if (!_ready) return _stackLabels(labels);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) return _stackLabels(labels);
        final direction = Directionality.of(context);
        final overflows = [
          for (final label in labels)
            _measureOverflow(context, label, constraints, direction),
        ];
        if (overflows.every((overflow) => overflow == null)) {
          return _stackLabels(labels);
        }
        return _ScrollingLabels(
          key: ValueKey((
            width,
            direction,
            overflows.first?.textWidth,
            overflows.last?.textWidth,
          )),
          labels: labels,
          overflows: overflows,
          width: width,
          direction: direction,
        );
      },
    );
  }
}

typedef _Overflow = ({String text, double textWidth, double height});

_Overflow? _measureOverflow(
  BuildContext context,
  Text label,
  BoxConstraints constraints,
  TextDirection direction,
) {
  final defaults = DefaultTextStyle.of(context);
  final effectiveStyle = defaults.style.merge(label.style);
  final text = label.data!;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: MediaQuery.boldTextOf(context)
          ? effectiveStyle.merge(const TextStyle(fontWeight: FontWeight.bold))
          : effectiveStyle,
    ),
    textDirection: direction,
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    textHeightBehavior:
        defaults.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context),
    maxLines: label.maxLines,
    ellipsis: '…',
  );
  try {
    painter.layout(maxWidth: constraints.maxWidth);
    if (!painter.didExceedMaxLines) return null;

    final height = constraints.constrainHeight(painter.height);
    final singleLine = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    painter
      ..text = TextSpan(text: singleLine, style: painter.text!.style)
      ..maxLines = 1
      ..ellipsis = null
      ..layout();
    final textWidth = painter.width.ceilToDouble();
    if (textWidth <= constraints.maxWidth) return null;
    return (text: singleLine, textWidth: textWidth, height: height);
  } finally {
    painter.dispose();
  }
}

class _ScrollingLabels extends StatefulWidget {
  const _ScrollingLabels({
    super.key,
    required this.labels,
    required this.overflows,
    required this.width,
    required this.direction,
  });

  final List<Text> labels;
  final List<_Overflow?> overflows;
  final double width;
  final TextDirection direction;

  @override
  State<_ScrollingLabels> createState() => _ScrollingLabelsState();
}

class _ScrollingLabelsState extends State<_ScrollingLabels>
    with SingleTickerProviderStateMixin {
  static const _endPause = Duration(seconds: 2);
  static const _rewindDuration = Duration(milliseconds: 300);
  Timer? _pause;
  late final AnimationController _motion;
  late final double _distance;

  @override
  void initState() {
    super.initState();
    _distance = widget.overflows.nonNulls
        .map((overflow) => overflow.textWidth - widget.width)
        .reduce(math.max);
    _motion =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (_distance * 1000 / 36).ceil()),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pause = Timer(_endPause, () {
              if (widget.labels.length == 1) {
                _motion.forward(from: 0);
              } else {
                _motion.animateBack(0, duration: _rewindDuration);
              }
            });
          } else if (status == AnimationStatus.dismissed &&
              widget.labels.length > 1) {
            _motion.forward();
          }
        });
    _motion.forward();
  }

  @override
  void dispose() {
    _pause?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _stackLabels([
    for (var i = 0; i < widget.labels.length; i++)
      if (widget.overflows[i] case final overflow?)
        _scrollingLine(widget.labels[i], overflow)
      else
        widget.labels[i],
  ]);

  Widget _scrollingLine(Text label, _Overflow overflow) => SizedBox(
    width: widget.width,
    height: overflow.height,
    child: Flow(
      delegate: _LabelMotion(
        _motion,
        overflow.textWidth,
        widget.direction,
        _distance,
      ),
      children: [
        Text(
          overflow.text,
          semanticsLabel: label.data,
          style: label.style,
          textAlign: TextAlign.start,
          softWrap: false,
          maxLines: 1,
        ),
      ],
    ),
  );
}

class _LabelMotion extends FlowDelegate {
  _LabelMotion(
    this.motion,
    this.textWidth,
    this.direction,
    this.longestDistance,
  ) : super(repaint: motion);

  final Animation<double> motion;
  final double textWidth;
  final TextDirection direction;
  final double longestDistance;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: textWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final distance = textWidth - context.size.width;
    // Share a speed going forward and a duration going back.
    final traveled = motion.status == AnimationStatus.reverse
        ? distance * motion.value
        : math.min(distance, longestDistance * motion.value);
    final offset = direction == TextDirection.ltr
        ? -traveled
        : traveled - distance;
    context.paintChild(0, transform: Matrix4.translationValues(offset, 0, 0));
  }

  @override
  bool shouldRelayout(_LabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth;

  @override
  bool shouldRepaint(_LabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth ||
      direction != oldDelegate.direction ||
      longestDistance != oldDelegate.longestDistance;
}
