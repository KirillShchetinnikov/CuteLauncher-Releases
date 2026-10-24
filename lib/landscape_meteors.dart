import 'dart:math' as math;

class LandscapeMeteorFlight {
  final double x, y, tailX, tailY, opacity;
  const LandscapeMeteorFlight(
    this.x,
    this.y,
    this.tailX,
    this.tailY,
    this.opacity,
  );
}

/// Sparse deterministic events. Between flights the scene needs no frame ticker.
class LandscapeMeteors {
  static const duration = 1.25;
  static double _period(bool demo) => demo ? 5.5 : 30;
  static List<double> _offsets(bool demo) =>
      demo ? const [.8, 3.6] : const [2, 18];

  static List<LandscapeMeteorFlight> at(double seconds, {bool demo = false}) {
    final period = _period(demo);
    final cycle = (seconds / period).floor();
    final phase = seconds - cycle * period;
    final result = <LandscapeMeteorFlight>[];
    for (var i = 0; i < 2; i++) {
      final elapsed = phase - _offsets(demo)[i];
      if (elapsed < 0 || elapsed >= duration) continue;
      final progress = elapsed / duration;
      final random = math.Random(781 + cycle * 719 + i * 37);
      final x = .13 + random.nextDouble() * .52;
      final y = .035 + random.nextDouble() * .055;
      final dx = .10 + random.nextDouble() * .09;
      final dy = .07 + random.nextDouble() * .06;
      final tail = math.min(1.0, progress * 5) * .35;
      result.add(
        LandscapeMeteorFlight(
          x + dx * progress,
          y + dy * progress,
          dx * tail,
          dy * tail,
          math.sin(progress * math.pi),
        ),
      );
    }
    return result;
  }

  static double untilBoundary(double seconds, {bool demo = false}) {
    final period = _period(demo);
    final phase = seconds % period;
    var wait = period;
    for (final offset in _offsets(demo)) {
      for (final boundary in [offset, offset + duration]) {
        var delta = boundary - phase;
        if (delta <= .000001) delta += period;
        wait = math.min(wait, delta);
      }
    }
    return wait;
  }
}
