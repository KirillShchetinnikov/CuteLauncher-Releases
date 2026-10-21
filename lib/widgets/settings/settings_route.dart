import 'package:flutter/material.dart';

class SettingsRoute<T> extends PageRouteBuilder<T> {
  SettingsRoute({super.settings, required WidgetBuilder builder})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}
