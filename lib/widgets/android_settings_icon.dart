import 'package:flutter/material.dart';

/// Shared Android settings symbol for the home screen and settings menus.
class AndroidSettingsIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const AndroidSettingsIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Icon(
            Icons.android,
            size: size * 0.88,
            color: color ?? const Color(0xFF3DDC84),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color == null ? const Color(0xFF14251C) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.04),
              child: Icon(
                Icons.settings,
                size: size * 0.52,
                color: color ?? Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
