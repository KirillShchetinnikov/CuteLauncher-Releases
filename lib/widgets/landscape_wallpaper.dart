import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../adaptive_landscape.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';

import 'adaptive_landscape_background.dart';
import 'background_raster_cache.dart';
import 'wallpaper_background.dart';

/// Keep the filtered terrain texture stable while weather particles move.
class LandscapeWallpaper extends StatelessWidget {
  final Gradient gradient;
  final double brightness, saturation, dimming;
  final bool memorySaver;
  final Widget? informationLayer;
  const LandscapeWallpaper({
    super.key,
    required this.gradient,
    this.brightness = 1,
    this.saturation = 1,
    this.dimming = 1,
    this.memorySaver = false,
    this.informationLayer,
  });

  // Clamping a brightened/oversaturated composite is not distributive over
  // alpha blending. Keep the original composition for those adjustments.
  bool get canSeparate =>
      brightness >= 0 &&
      brightness <= 1 &&
      saturation >= 0 &&
      saturation <= 1 &&
      !memorySaver;

  bool canSeparateAt(Size size, double ratio) =>
      canSeparate &&
      (size.width * ratio).ceil() * (size.height * ratio).ceil() * 4 <=
          16 * 1024 * 1024;

  Widget _background(Widget artwork) => WallpaperBackground(
    image: null,
    gradient: gradient,
    artwork: artwork,
    brightness: brightness,
    saturation: saturation,
    dimming: dimming,
    memorySaver: memorySaver,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final settings = context.watch<SettingsService>();
    final weather = context.watch<WeatherService?>();
    final fog =
        settings.landscape.fog &&
        weather?.stale != true &&
        landscapeWeather(weather?.weatherData) == LandscapeWeather.fog;
    // Keep the terrain texture within the existing 16 MiB cache budget.
    return ValueListenableBuilder<LandscapeDemoFrame?>(
      valueListenable: settings.landscapeDemo,
      builder: (context, demo, _) =>
          _scene(canSeparateAt(size, ratio) && demo == null && !fog),
    );
  }

  Widget _scene(bool separate) {
    // Static fog is cheaper in the original cached composition. A demo also
    // animates terrain lighting and seasons, so there is no stable
    // base to cache separately. Preserve its original single composition when
    // there is no information to place between terrain and effects. With
    // information, filter terrain and particle colors independently so the
    // text keeps its own styling; never raster-cache the text with the terrain.
    if (!separate && informationLayer == null) {
      return BackgroundRasterCache(
        enabled: !memorySaver,
        child: _background(const AdaptiveLandscapeBackground()),
      );
    }
    return AdaptiveLandscapeBackground(
      informationLayer: informationLayer,
      effectsFrameInterval: separate ? null : const Duration(milliseconds: 100),
      effectsColors: LandscapeEffectsColors(
        brightness: brightness,
        saturation: saturation,
        dimming: dimming,
      ),
      staticLayerBuilder: (child) => BackgroundRasterCache(
        enabled: !memorySaver,
        child: _background(child),
      ),
      effectsLayerBuilder: (child) => RepaintBoundary(child: child),
    );
  }
}
