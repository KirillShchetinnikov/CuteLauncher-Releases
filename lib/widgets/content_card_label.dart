import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Scrolls overflowing labels inside their original text bounds.
class ContentCardLabel extends StatelessWidget {
  const ContentCardLabel(
    this.text, {
    super.key,
    required this.scroll,
    this.loop = true,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.subtitle,
    this.subtitleStyle,
  });

  final String text;
  final bool scroll;
  final bool loop;
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
    return _FocusedLabels(labels: labels, loop: loop);
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
  const _FocusedLabels({required this.labels, required this.loop});

  final List<Text> labels;
  final bool loop;

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
        (oldWidget.loop != widget.loop ||
            oldWidget.labels.first.data != widget.labels.first.data ||
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
          loop: widget.loop,
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
    required this.loop,
  });

  final List<Text> labels;
  final List<_Overflow?> overflows;
  final double width;
  final TextDirection direction;
  final bool loop;

  @override
  State<_ScrollingLabels> createState() => _ScrollingLabelsState();
}

class _ScrollingLabelsState extends State<_ScrollingLabels>
    with SingleTickerProviderStateMixin {
  static const _speed = 36.0;
  final _distance = ValueNotifier<double>(0);
  Ticker? _ticker;
  AnimationController? _restartMotion;
  Timer? _endPause;
  late final double _longestOverflow = widget.overflows.nonNulls
      .map((overflow) => overflow.textWidth - widget.width)
      .reduce(math.max);

  @override
  void initState() {
    super.initState();
    if (widget.loop) {
      _ticker = createTicker((elapsed) {
        _distance.value =
            elapsed.inMicroseconds * _speed / Duration.microsecondsPerSecond;
      })..start();
      return;
    }

    final motion = _restartMotion = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_longestOverflow * 1000 / _speed).ceil(),
      ),
    );
    motion.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _endPause = Timer(const Duration(seconds: 2), () {
          if (widget.labels.length == 1) {
            motion.forward(from: 0);
          } else {
            motion.animateBack(0, duration: const Duration(milliseconds: 300));
          }
        });
      } else if (status == AnimationStatus.dismissed &&
          widget.labels.length > 1) {
        motion.forward();
      }
    });
    motion.forward();
  }

  @override
  void dispose() {
    _endPause?.cancel();
    _ticker?.dispose();
    _restartMotion?.dispose();
    _distance.dispose();
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

  Widget _scrollingLine(Text label, _Overflow overflow) {
    final text = Text(
      overflow.text,
      style: label.style,
      textAlign: TextAlign.start,
      softWrap: false,
      maxLines: 1,
    );
    return Semantics(
      label: label.data,
      excludeSemantics: true,
      child: SizedBox(
        width: widget.width,
        height: overflow.height,
        child: Flow(
          delegate: widget.loop
              ? _LabelMotion(_distance, overflow.textWidth, widget.direction)
              : _RestartingLabelMotion(
                  _restartMotion!,
                  overflow.textWidth,
                  widget.direction,
                  _longestOverflow,
                ),
          children: [text, if (widget.loop) text],
        ),
      ),
    );
  }
}

class _RestartingLabelMotion extends FlowDelegate {
  _RestartingLabelMotion(
    this.motion,
    this.textWidth,
    this.direction,
    this.longestOverflow,
  ) : super(repaint: motion);

  final Animation<double> motion;
  final double textWidth;
  final TextDirection direction;
  final double longestOverflow;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: textWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final overflow = textWidth - context.size.width;
    final traveled = motion.status == AnimationStatus.reverse
        ? overflow * motion.value
        : math.min(overflow, longestOverflow * motion.value);
    final offset = direction == TextDirection.ltr
        ? -traveled
        : traveled - overflow;
    context.paintChild(0, transform: Matrix4.translationValues(offset, 0, 0));
  }

  @override
  bool shouldRelayout(_RestartingLabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth;

  @override
  bool shouldRepaint(_RestartingLabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth ||
      direction != oldDelegate.direction ||
      longestOverflow != oldDelegate.longestOverflow;
}

class _LabelMotion extends FlowDelegate {
  _LabelMotion(this.distance, this.textWidth, this.direction)
    : super(repaint: distance);

  final ValueListenable<double> distance;
  final double textWidth;
  final TextDirection direction;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: textWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final width = context.size.width;
    final period = textWidth + math.min(24.0, width / 3);
    final traveled = distance.value % period;
    final ltr = direction == TextDirection.ltr;
    final sign = ltr ? -1.0 : 1.0;
    final offset = (ltr ? 0.0 : width - textWidth) + sign * traveled;
    if (traveled < textWidth) {
      context.paintChild(0, transform: Matrix4.translationValues(offset, 0, 0));
    }
    if (traveled > period - width) {
      context.paintChild(
        1,
        transform: Matrix4.translationValues(offset - sign * period, 0, 0),
      );
    }
  }

  @override
  bool shouldRelayout(_LabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth;

  @override
  bool shouldRepaint(_LabelMotion oldDelegate) =>
      textWidth != oldDelegate.textWidth ||
      direction != oldDelegate.direction ||
      distance != oldDelegate.distance;
}
