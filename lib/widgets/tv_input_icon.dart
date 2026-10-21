import 'package:flutter/material.dart';

import '../models/tv_input.dart';

IconData tvInputIcon(TvInput input) => switch (input.icon) {
  'hdmi' => Icons.settings_input_hdmi,
  'tv' => Icons.tv,
  'game' => Icons.sports_esports,
  'computer' => Icons.computer,
  'receiver' => Icons.speaker,
  'disc' => Icons.album,
  'stream' => Icons.cast,
  _ => switch (input.type) {
    TvInputType.hdmi => Icons.settings_input_hdmi,
    TvInputType.tuner => Icons.settings_input_antenna_outlined,
    TvInputType.av => Icons.settings_input_component_outlined,
    _ => Icons.input_outlined,
  },
};
