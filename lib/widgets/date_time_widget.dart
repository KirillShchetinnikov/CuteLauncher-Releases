/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flauncher/date_time_format.dart';

import '../panel_clock_style.dart';

import 'animated_character.dart';

class DateTimeWidget extends StatefulWidget {
  final Duration? updateInterval;
  final String _dateTimeFormatString;
  final TextStyle? textStyle;
  final bool animate;
  final DateTime? fixedTime;
  final PanelClockStyle? clockStyle;

  const DateTimeWidget(
    String dateTimeFormatString, {
    super.key,
    this.updateInterval,
    this.textStyle,
    this.animate = true,
    this.fixedTime,
    this.clockStyle,
  }) : _dateTimeFormatString = dateTimeFormatString;

  @override
  State<DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget>
    with WidgetsBindingObserver {
  late DateTime _now;
  late LauncherDateFormatter _formatter;
  String _formattedText = '';
  Timer? _timer;
  List<(DateFormat, String)> _clockParts = const [];
  // Preserve quoted literals and group repeated date-format letters.
  static final _tokens = RegExp(r"'(?:[^']|'')*'|([a-zA-Z])\1*|[^a-zA-Z']+|'");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initDateFormatAndRefresh();
  }

  void _initDateFormatAndRefresh() {
    _formatter = LauncherDateFormatter(
      widget._dateTimeFormatString,
      Localizations.localeOf(context).toString(),
    );
    _now = widget.fixedTime ?? DateTime.now();
    _formattedText = _format(_now);
    _clockParts = widget.clockStyle == null
        ? const []
        : [
            for (final match in _tokens.allMatches(
              widget._dateTimeFormatString,
            ))
              (
                // A literal suffix prevents intl interpreting a single token
                // such as H as a locale-dependent skeleton (which may add 0).
                DateFormat(
                  '${match[0]!}|',
                  Localizations.localeOf(context).toString(),
                ),
                match[0]!.startsWith("'") ? '' : match[0]![0],
              ),
          ];
  }

  String _format(DateTime date) => _formatter.format(date);

  void _startTimer() {
    _timer?.cancel();
    if (widget.fixedTime != null) return;
    final interval = widget.updateInterval ?? _defaultInterval();
    _timer = Timer.periodic(interval, (_) => _refreshTime());
  }

  /// Returns 1-second interval by default so time updates immediately when NTP sync completes or minute rolls over.
  Duration _defaultInterval() {
    return const Duration(seconds: 1);
  }

  @override
  void didUpdateWidget(DateTimeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update format if it changed or updateInterval changed
    if (oldWidget._dateTimeFormatString != widget._dateTimeFormatString ||
        oldWidget.updateInterval != widget.updateInterval ||
        oldWidget.fixedTime != widget.fixedTime ||
        (oldWidget.clockStyle == null) != (widget.clockStyle == null)) {
      _initDateFormatAndRefresh();
      _startTimer();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTime(force: true);
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget.clockStyle;
    final clockColor = clock?.clockColor;
    final textStyle = clockColor == null
        ? widget.textStyle
        : PanelClockStyle.withTextColor(
            widget.textStyle ?? DefaultTextStyle.of(context).style,
            clockColor,
          );
    if (clock != null &&
        (clock.hoursColor != null ||
            clock.minutesColor != null ||
            !clock.showColon)) {
      final base = textStyle ?? DefaultTextStyle.of(context).style;
      String partText(DateFormat formatter) {
        final text = formatter.format(_now);
        return text.substring(0, text.length - 1);
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (formatter, token) in _clockParts)
            for (final char in partText(formatter).split(''))
              Opacity(
                opacity: char == ':' && !clock.showColon ? 0 : 1,
                child: AnimatedCharacter(
                  character: char,
                  animate: widget.animate,
                  textStyle: PanelClockStyle.withTextColor(
                    base,
                    'HhKk'.contains(token) && token.isNotEmpty
                        ? clock.hoursColor
                        : token == 'm'
                        ? clock.minutesColor
                        : null,
                  ),
                ),
              ),
        ],
      );
    }
    final formattedText = _formattedText.isNotEmpty
        ? _formattedText
        : _format(_now);

    return AnimatedTimeDisplay(
      displayText: formattedText,
      textStyle: textStyle,
      animate: widget.animate,
    );
  }

  void _refreshTime({bool force = false}) {
    final now = widget.fixedTime ?? DateTime.now();
    final newFormattedText = _format(now);

    if (force || newFormattedText != _formattedText) {
      setState(() {
        _now = now;
        _formattedText = newFormattedText;
      });
    }
  }
}
