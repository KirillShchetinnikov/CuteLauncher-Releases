import 'package:flutter/material.dart';

import 'panel_calendar_dialog.dart';
import 'weather_forecast_menu.dart';

/// Keeps the same menu route while its configured content changes in settings.
class InformationMenu extends StatefulWidget {
  final Rect anchor;
  final String initialAction;
  final bool weatherOrigin;
  final String? Function()? resolveAction;

  const InformationMenu({
    super.key,
    required this.anchor,
    required this.initialAction,
    required this.weatherOrigin,
    this.resolveAction,
  });

  @override
  State<InformationMenu> createState() => _InformationMenuState();
}

class _InformationMenuState extends State<InformationMenu> {
  late String _action = widget.initialAction;
  bool _restoreSettingsFocus = false;

  void _settingsClosed() {
    final action = widget.resolveAction != null
        ? widget.resolveAction!()
        : widget.initialAction;
    if (action == null || action == 'none') {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _action = action;
      _restoreSettingsFocus = true;
    });
  }

  @override
  Widget build(BuildContext context) => _action == 'calendar'
      ? PanelCalendarDialog(
          anchor: widget.anchor,
          autofocusSettings: _restoreSettingsFocus,
          onSettingsClosed: _settingsClosed,
        )
      : WeatherForecastMenu(
          anchor: widget.anchor,
          showCalendar: _action == 'both',
          autofocusSettings: _restoreSettingsFocus ? true : null,
          onSettingsClosed: _settingsClosed,
        );
}
