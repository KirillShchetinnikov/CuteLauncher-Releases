import 'package:flutter/material.dart';

import 'settings_slider_tile.dart';

class SettingsPercentageSlider extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  const SettingsPercentageSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SettingsSliderTile(
    title: title,
    value: value,
    options: [for (var i = 0; i <= 100; i++) i / 100],
    label: (value) => '${(value * 100).round()}%',
    onChanged: (value) => onChanged(value.toDouble()),
  );
}
