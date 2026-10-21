import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../image_limits.dart';

/// Bounded image decoding shared by the foreground and its optional blurred copy.
class WallpaperBackground extends StatelessWidget {
  final ImageProvider? image;
  final Gradient gradient;
  final String mode;
  final double brightness;
  final double saturation;
  final double dimming;
  final bool memorySaver;
  final Widget? artwork;

  const WallpaperBackground({
    super.key,
    required this.image,
    required this.gradient,
    this.mode = 'cover',
    this.brightness = 1,
    this.saturation = 1,
    this.dimming = 1,
    this.memorySaver = false,
    this.artwork,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final provider = image;
    Widget fallback() =>
        DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    Widget picture(BoxFit fit) => Image(
      image: sizedImage(
        provider!,
        size,
        MediaQuery.devicePixelRatioOf(context),
      ),
      fit: fit,
      width: size.width,
      height: size.height,
      errorBuilder: (_, _, _) => fallback(),
    );
    Widget background = artwork ?? fallback();
    if (provider != null) {
      background = Stack(
        fit: StackFit.expand,
        children: [
          if (mode == 'blurred' && !memorySaver)
            ClipRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                  tileMode: TileMode.clamp,
                ),
                child: picture(BoxFit.cover),
              ),
            ),
          picture(mode == 'cover' ? BoxFit.cover : BoxFit.contain),
        ],
      );
    }
    final inverse = 1 - saturation;
    final r = inverse * .2126;
    final g = inverse * .7152;
    final b = inverse * .0722;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (brightness == 1 && saturation == 1) background else ColorFiltered(
          colorFilter: ColorFilter.matrix([
            (r + saturation) * brightness,
            g * brightness,
            b * brightness,
            0,
            0,
            r * brightness,
            (g + saturation) * brightness,
            b * brightness,
            0,
            0,
            r * brightness,
            g * brightness,
            (b + saturation) * brightness,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: background,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                for (final alpha in [.35, .15, .45])
                  Colors.black.withValues(alpha: (alpha * dimming).clamp(0, 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
