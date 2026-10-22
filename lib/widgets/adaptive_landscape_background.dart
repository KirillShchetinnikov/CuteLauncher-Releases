import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../adaptive_landscape.dart';
import '../providers/launcher_state.dart';
import '../providers/night_mode_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import '../image_limits.dart';

/// Bounded procedural scene and one decoded photo. Hidden Home does no work.
class AdaptiveLandscapeBackground extends StatefulWidget {
  const AdaptiveLandscapeBackground({super.key});
  @override
  State<AdaptiveLandscapeBackground> createState() => _LandscapeState();
}

class _LandscapeState extends State<AdaptiveLandscapeBackground>
    with WidgetsBindingObserver {
  Timer? _clock, _motion;
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
    final active =
        _foreground && visible && TickerMode.valuesOf(context).enabled;
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
    final source = context.watch<WeatherService?>();
    final condition = source?.stale == true
        ? LandscapeWeather.clear
        : landscapeWeather(source?.weatherData);
    final precipitation =
        condition == LandscapeWeather.rain ||
        condition == LandscapeWeather.snow;
    final visibleMotion =
        settings.landscape.precipitation && precipitation ||
        settings.landscape.clouds &&
            (precipitation || condition == LandscapeWeather.cloudy);
    final moving =
        active &&
        visibleMotion &&
        settings.landscape.motion &&
        !settings.memorySaverEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (moving) {
      _motion ??= Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _frame.value = (_frame.value + .1) % 120,
      );
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
    } else if (mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _motion?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _configure();
    final settings = context.watch<SettingsService>();
    final config = settings.landscape;
    final weather = context.watch<WeatherService?>();
    final night = context.watch<NightModeService?>();
    final coordinates = weather?.configuration;
    final latitude = coordinates?.locationMode.name == 'manual'
        ? coordinates?.cityLatitude
        : coordinates?.latitude;
    final season = landscapeSeason(
      _now,
      config,
      latitude: latitude ?? night?.configuration.latitude,
    );
    final phase = landscapePhase(
      _now,
      config,
      solarDays: night?.solarDays ?? const [],
    );
    final condition = weather?.stale == true
        ? LandscapeWeather.clear
        : landscapeWeather(weather?.weatherData);
    final staticScene = RepaintBoundary(
      child: config.variant == 'realistic'
          ? _PhotoScene(season: season, phase: phase)
          : CustomPaint(
              painter: LandscapePainter(season, phase),
              child: const SizedBox.expand(),
            ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration:
                  settings.memorySaverEnabled ||
                      MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(seconds: 3),
              child: SizedBox.expand(
                key: ValueKey('${config.variant}_${season.name}_${phase.name}'),
                child: staticScene,
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
  const _PhotoScene({required this.season, required this.phase});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tint = switch (phase) {
      LandscapePhase.day => Colors.transparent,
      LandscapePhase.dawn => const Color(0x44896B92),
      LandscapePhase.dusk => const Color(0x667A3F28),
      LandscapePhase.night => const Color(0xCD06152F),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: sizedImage(
            AssetImage(
              'assets/landscapes/${season == LandscapeSeason.summer ? 'valley' : season.name}.png',
            ),
            size,
            MediaQuery.devicePixelRatioOf(context),
          ),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              CustomPaint(painter: LandscapePainter(season, phase)),
        ),
        ColoredBox(color: tint),
        if (phase == LandscapePhase.night)
          CustomPaint(painter: _StarsPainter()),
      ],
    );
  }
}

class LandscapePainter extends CustomPainter {
  final LandscapeSeason season;
  final LandscapePhase phase;
  LandscapePainter(this.season, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final night = phase == LandscapePhase.night;
    final sky = switch (phase) {
      LandscapePhase.dawn => [const Color(0xFF59678F), const Color(0xFFF1B8A3)],
      LandscapePhase.day => [const Color(0xFF73A4C8), const Color(0xFFDAE8E3)],
      LandscapePhase.dusk => [const Color(0xFF4E557F), const Color(0xFFE4A27C)],
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
          colors: sky,
        ).createShader(Offset.zero & size),
    );
    final sun = Offset(w * .72, h * (phase == LandscapePhase.day ? .18 : .36));
    canvas.drawCircle(
      sun,
      h * .035,
      Paint()
        ..color = night ? const Color(0xFFE6E7D9) : const Color(0xFFFFE1B3),
    );
    if (night) _StarsPainter().paint(canvas, size);
    final colours = switch (season) {
      LandscapeSeason.spring => [
        const Color(0xFF83AAA0),
        const Color(0xFF60877B),
        const Color(0xFF3B6658),
        const Color(0xFF244F43),
      ],
      LandscapeSeason.summer => [
        const Color(0xFF749B91),
        const Color(0xFF527F70),
        const Color(0xFF376A52),
        const Color(0xFF244B3A),
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
    Color tone(Color c) => night
        ? Color.lerp(c, const Color(0xFF111D38), .65)!
        : phase == LandscapePhase.dusk
        ? Color.lerp(c, const Color(0xFF7F5867), .16)!
        : c;
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
              : const Color(0xFF89AFB4),
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
                : const Color(0xFF294C43),
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
    final light = night || phase == LandscapePhase.dusk;
    for (var i = 0; i < 2; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          house.left + w * (.008 + i * .023),
          house.top + h * .012,
          w * .009,
          h * .017,
        ),
        Paint()
          ..color = light ? const Color(0xFFFFD28C) : const Color(0xFF91B4BA),
      );
    }
    if (season == LandscapeSeason.spring) {
      for (var i = 0; i < 45; i++) {
        canvas.drawCircle(
          Offset(w * ((i * 31 % 100) / 100), h * (.86 + (i % 7) * .018)),
          h * .0018,
          Paint()..color = const Color(0xFFD9C9B1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LandscapePainter old) =>
      old.season != season || old.phase != phase;
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFC7D5E6);
    if (size.isEmpty) return;
    for (var i = 0; i < 65; i++) {
      canvas.drawCircle(
        Offset(
          (i * 157.3 + 23) % size.width,
          (i * 51.7 + 10) % (size.height * .28),
        ),
        i % 5 == 0 ? 1.2 : .6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => false;
}

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
        ..color = Colors.white.withValues(alpha: snow ? .62 : .25)
        ..strokeWidth = 1;
      for (var i = 0; i < (snow ? 70 : 95); i++) {
        final x = (i * 113.3 + (snow ? math.sin(t * .3 + i) * 10 : t * 13)) % w;
        final y = (i * 71.7 + t * (snow ? 14 : 170)) % h;
        if (snow) {
          canvas.drawCircle(Offset(x, y), i % 3 + 1.0, paint);
        } else {
          canvas.drawLine(Offset(x, y), Offset(x - 3, y + h * .018), paint);
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
