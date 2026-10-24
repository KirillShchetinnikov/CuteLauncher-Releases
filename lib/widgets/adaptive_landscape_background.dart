import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../adaptive_landscape.dart';
import '../landscape_meteors.dart';
import '../providers/launcher_state.dart';
import '../providers/night_mode_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import '../image_limits.dart';
import 'landscape_horizon.dart';

/// Bounded procedural scene and one decoded photo. Hidden Home does no work.
class AdaptiveLandscapeBackground extends StatefulWidget {
  const AdaptiveLandscapeBackground({super.key});
  @override
  State<AdaptiveLandscapeBackground> createState() => _LandscapeState();
}

class _LandscapeState extends State<AdaptiveLandscapeBackground>
    with WidgetsBindingObserver {
  Timer? _clock, _motion, _meteorWake;
  final _animationClock = Stopwatch();
  final _frame = ValueNotifier<double>(0);
  DateTime _now = DateTime.now();
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  void _configure() {
    final settings = context.watch<SettingsService>();
    final visible = context.watch<LauncherState?>()?.launcherVisible ?? true;
    final demo = settings.landscapeDemo.value;
    final active =
        _foreground &&
        (visible || demo != null) &&
        TickerMode.valuesOf(context).enabled;
    if (active &&
        (settings.landscape.timeOfDay || settings.landscape.seasons)) {
      _now = DateTime.now();
      _clock ??= Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    } else {
      _clock?.cancel();
      _clock = null;
    }
    final config = demo == null
        ? settings.landscape
        : settings.landscape.forDemo();
    final source = context.watch<WeatherService?>();
    final condition =
        demo?.weather ??
        (source?.stale == true
            ? LandscapeWeather.clear
            : landscapeWeather(source?.weatherData));
    final precipitation =
        condition == LandscapeWeather.rain ||
        condition == LandscapeWeather.snow;
    final weatherMoving =
        config.motion &&
        (config.precipitation && precipitation ||
            config.clouds &&
                (precipitation || condition == LandscapeWeather.cloudy));
    final animated =
        active &&
        !settings.memorySaverEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animated) {
      _animationClock.start();
    } else {
      _animationClock.stop();
    }
    final seconds =
        _animationClock.elapsedMicroseconds / Duration.microsecondsPerSecond;
    final lighting = landscapeLight(
      demo?.now ?? _now,
      config,
      solarDays:
          demo?.timeline.solarDays ??
          context.watch<NightModeService?>()?.solarDays ??
          const [],
    );
    final skyMoving = animated && landscapeNightOpacity(lighting) > 0;
    final meteorMoving =
        skyMoving &&
        LandscapeMeteors.at(seconds, demo: demo != null).isNotEmpty;
    _meteorWake?.cancel();
    _meteorWake = null;
    if (skyMoving) {
      final wait = LandscapeMeteors.untilBoundary(seconds, demo: demo != null);
      _meteorWake = Timer(
        Duration(microseconds: (wait * Duration.microsecondsPerSecond).ceil()),
        () {
          if (mounted) setState(() {});
        },
      );
    }
    final moving = animated && (weatherMoving || meteorMoving);
    // Capture can supply scene frames at vsync; moving particles stay at 10 Hz.
    if (_motion == null || !moving) _frame.value = seconds;
    if (moving) {
      _motion ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          _frame.value =
              _animationClock.elapsedMicroseconds /
              Duration.microsecondsPerSecond;
        }
      });
    } else {
      _motion?.cancel();
      _motion = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // Dependency registration belongs to didChangeDependencies/build.
    if (!_foreground) {
      _clock?.cancel();
      _clock = null;
      _motion?.cancel();
      _motion = null;
      _meteorWake?.cancel();
      _meteorWake = null;
      _animationClock.stop();
    } else if (mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _motion?.cancel();
    _meteorWake?.cancel();
    _animationClock.stop();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return ValueListenableBuilder<LandscapeDemoFrame?>(
      valueListenable: settings.landscapeDemo,
      builder: (context, demo, _) => _buildScene(context, settings, demo),
    );
  }

  Widget _buildScene(
    BuildContext context,
    SettingsService settings,
    LandscapeDemoFrame? demo,
  ) {
    _configure();
    final config = demo == null
        ? settings.landscape
        : settings.landscape.forDemo();
    final now = demo?.now ?? _now;
    final weather = context.watch<WeatherService?>();
    final night = context.watch<NightModeService?>();
    final coordinates = weather?.configuration;
    final latitude = coordinates?.locationMode.name == 'manual'
        ? coordinates?.cityLatitude
        : coordinates?.latitude;
    final season =
        demo?.season ??
        landscapeSeason(
          now,
          config,
          latitude: latitude ?? night?.configuration.latitude,
        );
    final phase = landscapePhase(
      now,
      config,
      solarDays: demo?.timeline.solarDays ?? night?.solarDays ?? const [],
    );
    final lighting = landscapeLight(
      now,
      config,
      solarDays: demo?.timeline.solarDays ?? night?.solarDays ?? const [],
    );
    final glow = LandscapeGlow.at(
      now,
      config,
      solarDays: demo?.timeline.solarDays ?? night?.solarDays ?? const [],
    );
    final starAngle = landscapeStarAngle(now, config);
    final bodies = config.celestialBodies
        ? LandscapeCelestialState.at(
            now,
            config,
            solarDays: demo?.timeline.solarDays ?? night?.solarDays ?? const [],
          )
        : null;
    final condition =
        demo?.weather ??
        (weather?.stale == true
            ? LandscapeWeather.clear
            : landscapeWeather(weather?.weatherData));
    final staticScene = RepaintBoundary(
      child: config.variant == 'realistic'
          ? _PhotoScene(
              season: season,
              phase: phase,
              lighting: lighting,
              bodies: bodies,
              starAngle: starAngle,
              glow: glow,
            )
          : CustomPaint(
              painter: LandscapePainter(
                season,
                phase,
                lighting: lighting,
                bodies: bodies,
                starAngle: starAngle,
                glow: glow,
              ),
              child: const SizedBox.expand(),
            ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              // Old normal-mode controllers keep their original 3s duration.
              // Recreate them at demo boundaries so every season uses 500ms.
              key: ValueKey(demo != null),
              duration:
                  settings.memorySaverEnabled ||
                      MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : demo != null
                  ? const Duration(milliseconds: 500)
                  : const Duration(seconds: 3),
              child: SizedBox.expand(
                key: ValueKey('${config.variant}_${season.name}'),
                child: staticScene,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: LandscapeMeteorsPainter(
                  _frame,
                  nightOpacity: landscapeNightOpacity(lighting),
                  season: season,
                  photographic: config.variant == 'realistic',
                  demo: demo != null,
                  enabled:
                      _foreground &&
                      (demo != null ||
                          (context.watch<LauncherState?>()?.launcherVisible ??
                              true)) &&
                      TickerMode.valuesOf(context).enabled &&
                      !settings.memorySaverEnabled &&
                      !MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: LandscapeEffectsPainter(
                  config,
                  condition,
                  phase,
                  _frame,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoScene extends StatelessWidget {
  final LandscapeSeason season;
  final LandscapePhase phase;
  final LandscapeLight lighting;
  final LandscapeCelestialState? bodies;
  final double starAngle;
  final LandscapeGlow glow;
  const _PhotoScene({
    required this.season,
    required this.phase,
    required this.lighting,
    required this.bodies,
    required this.starAngle,
    required this.glow,
  });
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    Color tintFor(LandscapePhase phase) => switch (phase) {
      LandscapePhase.day => Colors.transparent,
      LandscapePhase.dawn => const Color(0x226C7799),
      LandscapePhase.dusk => const Color(0x334D4061),
      LandscapePhase.twilight => const Color(0xA02A244F),
      LandscapePhase.night => const Color(0xCD06152F),
    };
    final photo = Image(
      image: sizedImage(
        AssetImage(
          'assets/landscapes/${season == LandscapeSeason.summer ? 'valley' : season.name}.png',
        ),
        size,
        MediaQuery.devicePixelRatioOf(context),
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => CustomPaint(
        painter: LandscapePainter(season, phase, lighting: lighting),
      ),
    );
    // dart format off
    final filter = switch (season) {
      LandscapeSeason.spring => const ColorFilter.matrix([
        1.01, 0, -.02, 0, 4,
        0, 1.06, 0, 0, 5,
        -.01, 0, .99, 0, 2,
        0, 0, 0, 1, 0,
      ]),
      LandscapeSeason.summer => const ColorFilter.matrix([
        1.04, 0, 0, 0, 3,
        0, .98, 0, 0, 0,
        0, 0, .88, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      _ => null,
    };
    // dart format on
    return Stack(
      fit: StackFit.expand,
      children: [
        if (filter == null)
          photo
        else
          ColorFiltered(colorFilter: filter, child: photo),
        CustomPaint(
          painter: LandscapeSeasonAccentsPainter(season, photographic: true),
        ),
        ColoredBox(
          color: Color.lerp(
            tintFor(lighting.from),
            tintFor(lighting.to),
            lighting.mix,
          )!,
        ),
        CustomPaint(
          painter: LandscapeSkyGlowPainter(
            glow,
            photographic: true,
            season: season,
          ),
        ),
        if (bodies != null)
          CustomPaint(
            painter: LandscapeCelestialPainter(
              bodies!,
              photoHorizon: true,
              season: season,
            ),
          ),
        Opacity(
          opacity: Color.lerp(
            lighting.from == LandscapePhase.night
                ? Colors.white
                : Colors.transparent,
            lighting.to == LandscapePhase.night
                ? Colors.white
                : Colors.transparent,
            lighting.mix,
          )!.a,
          child: CustomPaint(
            painter: LandscapeStarsPainter(
              angle: starAngle,
              photoHorizon: true,
              season: season,
            ),
          ),
        ),
      ],
    );
  }
}

/// Separate bodies travel behind the terrain; they never turn into one another.
class LandscapeCelestialPainter extends CustomPainter {
  final LandscapeCelestialState bodies;
  final bool photoHorizon;
  final LandscapeSeason season;
  const LandscapeCelestialPainter(
    this.bodies, {
    this.photoHorizon = false,
    this.season = LandscapeSeason.summer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    final horizon = LandscapeHorizon(size, season, photographic: photoHorizon);
    canvas.clipPath(horizon.sky);
    void body(double progress, {required bool moon}) {
      if (moon
          ? (progress < -.12 || progress > 1.12)
          : (progress <= 0 || progress >= 1)) {
        return;
      }
      final elevation = math.sin(progress * math.pi);
      final sun = horizon.sunDisc(progress);
      final centre = moon
          ? Offset(
              size.width * (.18 + .64 * progress),
              size.height * (.46 - .32 * elevation),
            )
          : sun.centre;
      final radius = moon ? size.height * .026 : sun.radius;
      final color = moon
          ? const Color(0xFFE2E7EF)
          : Color.lerp(
              const Color(0xFFFFEDD0),
              const Color(0xFFFF6936),
              bodies.sunWarmth,
            )!;
      canvas.drawCircle(
        centre,
        radius * 2.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: moon ? .10 : .18),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: radius * 2.4)),
      );
      canvas.drawCircle(centre, radius, Paint()..color = color);
      if (moon) {
        for (final crater in [
          const Offset(-.28, -.18),
          const Offset(.30, .25),
          const Offset(-.05, .45),
        ]) {
          canvas.drawCircle(
            centre + crater * radius,
            radius * .13,
            Paint()..color = const Color(0xFFBFC9D8),
          );
        }
      }
    }

    body(bodies.sunProgress, moon: false);
    body(bodies.moonProgress, moon: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LandscapeCelestialPainter old) =>
      old.bodies.sunProgress != bodies.sunProgress ||
      old.bodies.moonProgress != bodies.moonProgress ||
      old.bodies.sunWarmth != bodies.sunWarmth ||
      old.photoHorizon != photoHorizon ||
      old.season != season;
}

/// Elliptical waves spread from the sun's horizon point, strongest in the sky.
class LandscapeSkyGlowPainter extends CustomPainter {
  final LandscapeGlow glow;
  final bool photographic;
  final LandscapeSeason season;
  const LandscapeSkyGlowPainter(
    this.glow, {
    this.photographic = false,
    this.season = LandscapeSeason.summer,
  });

  void _wave(Canvas canvas, Size size, double opacity) {
    final strength = glow.strength * opacity;
    canvas.save();
    final origin = LandscapeHorizon(
      size,
      season,
      photographic: photographic,
    ).sunHorizonPoint(glow.sunrise);
    canvas.translate(origin.dx, origin.dy - size.height * .025);
    canvas.scale(size.width * .95, size.height * .65);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8D4A).withValues(alpha: strength * .72),
            const Color(0xFFF16A4B).withValues(alpha: strength * .62),
            const Color(0xFFE76777).withValues(alpha: strength * .32),
            const Color(0xFFDC7899).withValues(alpha: strength * .16),
            const Color(0xFFE482A2).withValues(alpha: strength * .22),
            const Color(0xFFCB84A3).withValues(alpha: strength * .07),
            Colors.transparent,
          ],
          stops: const [0, .14, .32, .47, .59, .78, 1],
        ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || glow.strength <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (photographic) {
      // A faint reflected tint on the terrain, then the main glow only in sky.
      _wave(canvas, size, .08);
      canvas.saveLayer(Offset.zero & size, Paint());
      _wave(canvas, size, 1);
      // Feather the approximate ridge so no polygon edge appears against the photo.
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..blendMode = BlendMode.dstIn,
      );
      canvas.drawPath(
        LandscapeHorizon(size, season, photographic: true).sky,
        Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * .025),
      );
      canvas.restore();
      canvas.restore();
    } else {
      _wave(canvas, size, 1);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LandscapeSkyGlowPainter old) =>
      old.glow.strength != glow.strength ||
      old.glow.sunrise != glow.sunrise ||
      old.photographic != photographic ||
      old.season != season;
}

class LandscapePainter extends CustomPainter {
  final LandscapeSeason season;
  final LandscapePhase phase;
  final LandscapeLight? lighting;
  final LandscapeCelestialState? bodies;
  final double starAngle;
  final LandscapeGlow glow;
  LandscapePainter(
    this.season,
    this.phase, {
    this.lighting,
    this.bodies,
    this.starAngle = 0,
    this.glow = LandscapeGlow.none,
  });
  Color blend(Color Function(LandscapePhase) value) => lighting == null
      ? value(phase)
      : Color.lerp(value(lighting!.from), value(lighting!.to), lighting!.mix)!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    List<Color> skyFor(LandscapePhase phase) => switch (phase) {
      LandscapePhase.dawn => [const Color(0xFF5C6D97), const Color(0xFFCBD5DF)],
      LandscapePhase.day =>
        season == LandscapeSeason.spring
            ? [const Color(0xFF81BBD8), const Color(0xFFE5F1E5)]
            : season == LandscapeSeason.summer
            ? [const Color(0xFF709BC0), const Color(0xFFF2E6C4)]
            : [const Color(0xFF73A4C8), const Color(0xFFDAE8E3)],
      LandscapePhase.dusk => [const Color(0xFF4D547F), const Color(0xFFB8A8AF)],
      LandscapePhase.twilight => [
        const Color(0xFF242447),
        const Color(0xFF81608D),
      ],
      LandscapePhase.night => [
        const Color(0xFF0C1530),
        const Color(0xFF36466A),
      ],
    };
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [for (var i = 0; i < 2; i++) blend((p) => skyFor(p)[i])],
        ).createShader(Offset.zero & size),
    );
    LandscapeSkyGlowPainter(glow, season: season).paint(canvas, size);
    final nightWeight = blend(
      (p) => p == LandscapePhase.night ? Colors.white : Colors.transparent,
    ).a;
    if (bodies != null) {
      LandscapeCelestialPainter(bodies!, season: season).paint(canvas, size);
    }
    if (nightWeight > 0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: nightWeight),
      );
      LandscapeStarsPainter(angle: starAngle).paint(canvas, size);
      canvas.restore();
    }
    final colours = switch (season) {
      LandscapeSeason.spring => [
        const Color(0xFF9BC3AD),
        const Color(0xFF82B575),
        const Color(0xFF609D55),
        const Color(0xFF447D42),
      ],
      LandscapeSeason.summer => [
        const Color(0xFF81A18C),
        const Color(0xFF548761),
        const Color(0xFF2F6944),
        const Color(0xFF204C34),
      ],
      LandscapeSeason.autumn => [
        const Color(0xFFA5948F),
        const Color(0xFF967A65),
        const Color(0xFF826649),
        const Color(0xFF514D3D),
      ],
      LandscapeSeason.winter => [
        const Color(0xFFC5D6E3),
        const Color(0xFFAABFD0),
        const Color(0xFF8DA6BB),
        const Color(0xFF617E95),
      ],
    };
    Color tone(Color c) => blend(
      (phase) => phase == LandscapePhase.night
          ? Color.lerp(c, const Color(0xFF111D38), .65)!
          : phase == LandscapePhase.twilight
          ? Color.lerp(c, const Color(0xFF262341), .48)!
          : phase == LandscapePhase.dusk
          ? Color.lerp(c, const Color(0xFF7F5867), .16)!
          : c,
    );
    for (var i = 0; i < 4; i++) {
      final y = .40 + i * .13;
      final hill = Path()
        ..moveTo(0, h)
        ..lineTo(0, h * y)
        ..cubicTo(
          w * .18,
          h * (y - .17),
          w * .34,
          h * (y + .22),
          w * .56,
          h * (y + .05),
        )
        ..cubicTo(
          w * .75,
          h * (y - .14),
          w * .85,
          h * (y + .08),
          w,
          h * (y - .07),
        )
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(hill, Paint()..color = tone(colours[i]));
    }
    // A lake and its broad calm reflection sit behind the foreground trees.
    final lake = Path()
      ..moveTo(w * .2, h * .72)
      ..cubicTo(w * .35, h * .60, w * .50, h * .70, w * .69, h * .65)
      ..cubicTo(w * .66, h * .76, w * .46, h * .80, w * .30, h * .82)
      ..close();
    canvas.drawPath(
      lake,
      Paint()
        ..color = tone(
          season == LandscapeSeason.winter
              ? const Color(0xFFCEDDE2)
              : season == LandscapeSeason.spring
              ? const Color(0xFF94C9C2)
              : const Color(0xFF639EA6),
        ),
    );
    for (var i = 0; i < 28; i++) {
      final x = w * (i < 14 ? .015 + i * .018 : .73 + (i - 14) * .021);
      final y = h * (.67 + .05 * math.sin(i * 2));
      final treeHeight = h * (.055 + (i % 4) * .009);
      final tree = Path()
        ..moveTo(x, y - treeHeight)
        ..lineTo(x - treeHeight * .30, y)
        ..lineTo(x + treeHeight * .30, y)
        ..close();
      canvas.drawPath(
        tree,
        Paint()
          ..color = tone(
            season == LandscapeSeason.winter
                ? const Color(0xFFCDD9DE)
                : season == LandscapeSeason.spring
                ? const Color(0xFF427B50)
                : const Color(0xFF234F37),
          ),
      );
    }
    final house = Rect.fromLTWH(w * .28, h * .64, w * .047, h * .048);
    canvas.drawRect(house, Paint()..color = tone(const Color(0xFFB29C80)));
    final roof = Path()
      ..moveTo(house.left - w * .007, house.top)
      ..lineTo(house.center.dx, house.top - h * .027)
      ..lineTo(house.right + w * .007, house.top)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..color = season == LandscapeSeason.winter
            ? tone(const Color(0xFFF0EDE5))
            : const Color(0xFF493E3F),
    );
    final windowColor = blend(
      (p) =>
          p == LandscapePhase.night ||
              p == LandscapePhase.dusk ||
              p == LandscapePhase.twilight
          ? const Color(0xFFFFD28C)
          : const Color(0xFF91B4BA),
    );
    for (var i = 0; i < 2; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          house.left + w * (.008 + i * .023),
          house.top + h * .012,
          w * .009,
          h * .017,
        ),
        Paint()..color = windowColor,
      );
    }
    LandscapeSeasonAccentsPainter(
      season,
      lighting: lighting ?? LandscapeLight(phase, phase, 0),
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant LandscapePainter old) =>
      old.season != season ||
      old.phase != phase ||
      old.lighting != lighting ||
      old.bodies != bodies ||
      old.starAngle != starAngle ||
      old.glow != glow;
}

/// Static seasonal foreground details; weather animation never controls them.
class LandscapeSeasonAccentsPainter extends CustomPainter {
  final LandscapeSeason season;
  final LandscapeLight lighting;
  final bool photographic;
  const LandscapeSeasonAccentsPainter(
    this.season, {
    this.lighting = const LandscapeLight(
      LandscapePhase.day,
      LandscapePhase.day,
      0,
    ),
    this.photographic = false,
  });
  Color _tone(Color color) {
    double darkness(LandscapePhase phase) => switch (phase) {
      LandscapePhase.night => .78,
      LandscapePhase.twilight => .6,
      LandscapePhase.dusk => .2,
      _ => 0,
    };
    final darknessMix =
        darkness(lighting.from) * (1 - lighting.mix) +
        darkness(lighting.to) * lighting.mix;
    return Color.lerp(color, const Color(0xFF152439), darknessMix)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        (season != LandscapeSeason.spring &&
            season != LandscapeSeason.summer)) {
      return;
    }
    final w = size.width, h = size.height;
    final spring = season == LandscapeSeason.spring;
    final random = math.Random(0xB10550);
    if (spring && !photographic) {
      for (final (x, y) in const [(.11, .69), (.88, .67)]) {
        final base = Offset(w * x, h * y);
        canvas.drawLine(
          base,
          base - Offset(0, h * .09),
          Paint()
            ..strokeWidth = h * .007
            ..color = _tone(const Color(0xFF705E51)),
        );
        for (final (dx, dy) in const [
          (-.022, -.078),
          (.022, -.075),
          (0.0, -.10),
          (-.012, -.10),
          (.012, -.09),
          (0.0, -.067),
        ]) {
          canvas.drawCircle(
            base + Offset(h * dx, h * dy),
            h * .024,
            Paint()
              ..color = _tone(
                dx < 0 ? const Color(0xFFE6B6CE) : const Color(0xFFFFE4EC),
              ),
          );
        }
      }
    }
    for (var i = 0; i < (spring ? 105 : 48); i++) {
      final x =
          (i.isEven
              ? .02 + random.nextDouble() * .22
              : .73 + random.nextDouble() * .25) *
          w;
      final y = (.85 + random.nextDouble() * .145) * h;
      final stem = h * (.007 + random.nextDouble() * .012);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - stem * .15, y - stem),
        Paint()
          ..strokeWidth = .7
          ..color = _tone(
            spring ? const Color(0xFF688D48) : const Color(0xFFB8AD60),
          ),
      );
      if (spring) {
        final radius = h * (.002 + random.nextDouble() * .0025);
        final color = i % 3 == 0
            ? const Color(0xFFECA7CA)
            : const Color(0xFFFFF1DE);
        for (var petal = 0; petal < 4; petal++) {
          final angle = petal * math.pi / 2;
          canvas.drawCircle(
            Offset(
              x + math.cos(angle) * radius,
              y - stem + math.sin(angle) * radius,
            ),
            radius * .75,
            Paint()..color = _tone(color),
          );
        }
        canvas.drawCircle(
          Offset(x, y - stem),
          radius * .45,
          Paint()..color = _tone(const Color(0xFFE4C356)),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x - stem * .15, y - stem),
            width: h * .0025,
            height: h * .007,
          ),
          Paint()..color = _tone(const Color(0xFFCABD73)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LandscapeSeasonAccentsPainter old) =>
      old.season != season ||
      old.lighting != lighting ||
      old.photographic != photographic;
}

/// A seeded sky: irregular positions, stable across rebuilds and resizes.
class LandscapeStarsPainter extends CustomPainter {
  final double angle;
  final bool photoHorizon;
  final LandscapeSeason season;
  const LandscapeStarsPainter({
    this.angle = 0,
    this.photoHorizon = false,
    this.season = LandscapeSeason.summer,
  });
  static final _stars = _makeStars();
  static List<(double, double, double, double)> _makeStars() {
    final random = math.Random(0xC07E);
    return List.generate(700, (_) {
      final direction = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * .9;
      return (
        math.cos(direction) * radius,
        math.sin(direction) * radius,
        .35 + random.nextDouble() * .85,
        .35 + random.nextDouble() * .65,
      );
    }, growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.max(size.width, size.height);
    final pole = Offset(size.width * .5, size.height * .14);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * .30));
    if (photoHorizon) {
      canvas.clipPath(LandscapeHorizon(size, season, photographic: true).sky);
    }
    canvas.translate(pole.dx, pole.dy);
    canvas.rotate(angle);
    final paint = Paint();
    final cosine = math.cos(angle), sine = math.sin(angle);
    final visible = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height * .30,
    ).inflate(2);
    for (final (x, y, radius, opacity) in _stars) {
      final point = Offset(x * scale, y * scale);
      final screen =
          pole +
          Offset(
            point.dx * cosine - point.dy * sine,
            point.dx * sine + point.dy * cosine,
          );
      if (!visible.contains(screen)) continue;
      paint.color = const Color(0xFFDCE6F5).withValues(alpha: opacity);
      canvas.drawCircle(point, radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LandscapeStarsPainter old) =>
      old.angle != angle ||
      old.photoHorizon != photoHorizon ||
      old.season != season;
}

double landscapeNightOpacity(LandscapeLight light) =>
    (light.from == LandscapePhase.night ? 1.0 : 0.0) * (1 - light.mix) +
    (light.to == LandscapePhase.night ? 1.0 : 0.0) * light.mix;

class LandscapeMeteorsPainter extends CustomPainter {
  final ValueNotifier<double> frame;
  final double nightOpacity;
  final LandscapeSeason season;
  final bool photographic, demo, enabled;
  LandscapeMeteorsPainter(
    this.frame, {
    required this.nightOpacity,
    required this.season,
    this.photographic = false,
    this.demo = false,
    this.enabled = true,
  }) : super(repaint: frame);
  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled || nightOpacity <= 0 || size.isEmpty) return;
    canvas.save();
    canvas.clipPath(
      LandscapeHorizon(size, season, photographic: photographic).sky,
    );
    for (final meteor in LandscapeMeteors.at(frame.value, demo: demo)) {
      final head = Offset(meteor.x * size.width, meteor.y * size.height);
      final tail =
          head - Offset(meteor.tailX * size.width, meteor.tailY * size.height);
      final opacity = meteor.opacity * nightOpacity;
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFE0EFFF).withValues(alpha: opacity),
            ],
          ).createShader(Rect.fromPoints(tail, head)),
      );
      canvas.drawCircle(
        head,
        1.5,
        Paint()..color = const Color(0xFFF1F6FF).withValues(alpha: opacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LandscapeMeteorsPainter old) =>
      old.nightOpacity != nightOpacity ||
      old.season != season ||
      old.photographic != photographic ||
      old.demo != demo ||
      old.enabled != enabled ||
      old.frame != frame;
}

/// Rain falls slightly left, parallel to its visible streaks.
Offset landscapeRainPosition(int index, double seconds, Size size) => Offset(
  (index * 113.3 - seconds * 12.6) % size.width,
  (index * 71.7 + seconds * 105) % size.height,
);
Offset landscapeRainStreak(Size size) =>
    Offset(-size.height * .0215 * .12, size.height * .0215);

class LandscapeEffectsPainter extends CustomPainter {
  final LandscapeConfiguration config;
  final LandscapeWeather weather;
  final LandscapePhase phase;
  final ValueNotifier<double> frame;
  LandscapeEffectsPainter(this.config, this.weather, this.phase, this.frame)
    : super(repaint: frame);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = frame.value;
    if (config.clouds &&
        weather != LandscapeWeather.clear &&
        weather != LandscapeWeather.fog) {
      final paint = Paint()
        ..color =
            (phase == LandscapePhase.night
                    ? const Color(0xFF47546B)
                    : const Color(0xFFC5CCD0))
                .withValues(alpha: .40);
      for (var i = 0; i < 7; i++) {
        final x = ((i * w / 5 + t * w * .001) % (w * 1.4)) - w * .2;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, h * (.13 + i % 3 * .045)),
            width: w * .33,
            height: h * .075,
          ),
          paint,
        );
      }
    }
    if (config.precipitation &&
        (weather == LandscapeWeather.rain ||
            weather == LandscapeWeather.snow)) {
      final snow = weather == LandscapeWeather.snow;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: snow ? .62 : .45)
        ..strokeWidth = snow ? 1 : 1.3;
      final rainEdge = Paint()
        ..color = const Color(0x33304459)
        ..strokeWidth = 2;
      for (var i = 0; i < (snow ? 70 : 115); i++) {
        final position = snow
            ? Offset(
                (i * 113.3 + math.sin(t * .3 + i) * 10) % w,
                (i * 71.7 + t * 14) % h,
              )
            : landscapeRainPosition(i, t, size);
        final x = position.dx, y = position.dy;
        if (snow) {
          canvas.drawCircle(Offset(x, y), i % 3 + 1.0, paint);
        } else {
          final from = position, to = position + landscapeRainStreak(size);
          canvas.drawLine(from, to, rainEdge);
          canvas.drawLine(from, to, paint);
        }
      }
    }
    if (config.fog && weather == LandscapeWeather.fog) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x007F91A0),
              const Color(0xB3B5C3CA),
              const Color(0x6683949D),
            ],
          ).createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LandscapeEffectsPainter old) =>
      old.config.encode() != config.encode() ||
      old.weather != weather ||
      old.phase != phase ||
      old.frame != frame;
}
