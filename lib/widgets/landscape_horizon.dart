import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../adaptive_landscape.dart';
import '../landscape_horizon_data.dart';

/// The same screen-space ridge clips the sky and defines solar contact times.
class LandscapeHorizon {
  static final _cache = <(Size, LandscapeSeason, bool), LandscapeHorizon>{};
  final Size size;
  final List<Offset> ridge;
  late final Path sky = _skyPath();
  Path _skyPath() {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    for (final p in ridge.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  LandscapeHorizon._(this.size, this.ridge);

  factory LandscapeHorizon(
    Size size,
    LandscapeSeason season, {
    bool photographic = false,
  }) {
    final key = (
      size,
      photographic ? season : LandscapeSeason.summer,
      photographic,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    final points = photographic ? _photo(size, season) : _illustrated(size);
    final result = LandscapeHorizon._(size, List.unmodifiable(points));
    if (_cache.length >= 8) _cache.remove(_cache.keys.first);
    _cache[key] = result;
    return result;
  }

  static List<Offset> _photo(Size size, LandscapeSeason season) {
    final source = Size(landscapePhotoSize.$1, landscapePhotoSize.$2);
    final fit = applyBoxFit(BoxFit.cover, source, size);
    final crop = Alignment.center.inscribe(fit.source, Offset.zero & source);
    final target = Alignment.center.inscribe(
      fit.destination,
      Offset.zero & size,
    );
    return [
      for (final (x, y) in landscapePhotoRidges[season.name]!)
        Offset(
          target.left + (x - crop.left) * target.width / crop.width,
          target.top + (y - crop.top) * target.height / crop.height,
        ),
    ];
  }

  static List<Offset> _illustrated(Size size) {
    final result = <Offset>[];
    void curve(Offset a, Offset b, Offset c, Offset d) {
      for (var i = result.isEmpty ? 0 : 1; i <= 128; i++) {
        final t = i / 128, u = 1 - t;
        final p =
            a * (u * u * u) +
            b * (3 * u * u * t) +
            c * (3 * u * t * t) +
            d * (t * t * t);
        result.add(Offset(p.dx * size.width, p.dy * size.height));
      }
    }

    curve(
      const Offset(0, .4),
      const Offset(.18, .23),
      const Offset(.34, .62),
      const Offset(.56, .45),
    );
    curve(
      const Offset(.56, .45),
      const Offset(.75, .26),
      const Offset(.85, .48),
      const Offset(1, .33),
    );
    return result;
  }

  int _segment(double x) {
    var low = 0, high = ridge.length - 2;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (ridge[mid + 1].dx < x) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  double heightAt(double x) {
    final i = _segment(x);
    final a = ridge[i], b = ridge[i + 1];
    return a.dy + (b.dy - a.dy) * ((x - a.dx) / (b.dx - a.dx)).clamp(0, 1);
  }

  /// Lowest invisible circle centre: any upward movement exposes its first pixel.
  ({double centreY, Offset edge}) contact(double centreX, double radius) {
    var best = double.negativeInfinity;
    var edge = Offset(centreX, heightAt(centreX));
    for (var i = _segment(centreX - radius); i < ridge.length - 1; i++) {
      final a = ridge[i], b = ridge[i + 1];
      if (a.dx > centreX + radius) break;
      final left = math.max(a.dx, centreX - radius),
          right = math.min(b.dx, centreX + radius);
      if (right < left) continue;
      final slope = (b.dy - a.dy) / (b.dx - a.dx);
      final x = (centreX + slope * radius / math.sqrt(1 + slope * slope)).clamp(
        left,
        right,
      );
      final y = a.dy + slope * (x - a.dx);
      final centreY =
          y +
          math.sqrt(
            math.max(0, radius * radius - (x - centreX) * (x - centreX)),
          );
      if (centreY > best) {
        best = centreY;
        edge = Offset(x, y);
      }
    }
    return (centreY: best, edge: edge);
  }

  ({Offset centre, double radius}) sunDisc(double progress) {
    final radius = size.height * .030;
    final x = size.width * (.18 + .64 * progress);
    final tangent = contact(x, radius).centreY;
    final lift = math.max(size.height * .08, tangent - size.height * .14);
    return (
      centre: Offset(x, tangent - lift * math.sin(math.pi * progress)),
      radius: radius,
    );
  }

  Offset sunHorizonPoint(bool sunrise) =>
      contact(size.width * (sunrise ? .18 : .82), size.height * .030).edge;
}
