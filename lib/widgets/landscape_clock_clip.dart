import '../weather_sources.dart';
import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../adaptive_landscape.dart';
import '../providers/night_mode_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import 'landscape_horizon.dart';

/// Uses the existing terrain silhouette; no second landscape or image cache.
class LandscapeInformationGeometry extends StatefulWidget {
  final Widget Function(BuildContext, LandscapeHorizon) builder;
  const LandscapeInformationGeometry({super.key, required this.builder});

  @override
  State<LandscapeInformationGeometry> createState() =>
      _LandscapeInformationGeometryState();
}

class _LandscapeInformationGeometryState
    extends State<LandscapeInformationGeometry>
    with WidgetsBindingObserver {
  Timer? _midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    _midnight?.cancel();
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) setState(_schedule);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(_schedule);
    } else {
      _midnight?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final coordinates = context
        .select<
          WeatherService?,
          ({double? latitude, double? cityLatitude, String? mode})
        >(
          (s) => (
            latitude: s?.configuration.source == WeatherSource.customOpenMeteo
                ? s?.weatherData?.latitude : s?.configuration.latitude,
            cityLatitude: s?.configuration.cityLatitude,
            mode: s?.configuration.source == WeatherSource.customOpenMeteo
                ? 'automatic' : s?.configuration.locationMode.name,
          ),
        );
    final nightLatitude = context.select<NightModeService?, double?>(
      (s) => s?.configuration.latitude,
    );
    return ValueListenableBuilder<LandscapeDemoFrame?>(
      valueListenable: settings.landscapeDemo,
      builder: (context, demo, child) {
        final config = demo == null
            ? settings.landscape
            : settings.landscape.forDemo();
        final season =
            demo?.season ??
            landscapeSeason(
              settings.screenshotScene?.now ?? DateTime.now(),
              config,
              latitude:
                  (coordinates.mode == 'manual'
                      ? coordinates.cityLatitude
                      : coordinates.latitude) ??
                  nightLatitude,
            );
        return widget.builder(
          context,
          LandscapeHorizon(
            MediaQuery.sizeOf(context),
            season,
            photographic: config.variant == 'realistic',
          ),
        );
      },
    );
  }
}

/// Convert the screen-space skyline into the clock's coordinates at paint time.
/// This also accounts for the header offset, RTL placement and FittedBox scale.
class LandscapeSkyClip extends SingleChildRenderObjectWidget {
  final LandscapeHorizon horizon;
  const LandscapeSkyClip({
    super.key,
    required this.horizon,
    required super.child,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderLandscapeSkyClip(horizon);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderLandscapeSkyClip renderObject,
  ) {
    renderObject.horizon = horizon;
  }
}

class RenderLandscapeSkyClip extends RenderProxyBox {
  LandscapeHorizon _horizon;
  RenderLandscapeSkyClip(this._horizon);
  set horizon(LandscapeHorizon value) {
    if (identical(value, _horizon)) return;
    _horizon = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final transform = getTransformTo(null);
    if (transform.invert() == 0) return;
    final path = _horizon.sky.transform(transform.storage);
    // Retain the engine layer when unrelated Home painting reaches this mask.
    layer = context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      path,
      super.paint,
      clipBehavior: Clip.antiAlias,
      oldLayer: layer as ClipPathLayer?,
    );
  }
}
