enum FeedFormat {
  auto,
  landscape,
  portrait;

  double get aspectRatio => this == portrait ? 2 / 3 : 16 / 9;

  static FeedFormat majority(Iterable<double> ratios) {
    var portrait = 0, landscape = 0;
    for (final ratio in ratios) {
      if (!ratio.isFinite || ratio <= 0) continue;
      if (ratio < 1) {
        portrait++;
      } else {
        landscape++;
      }
    }
    return portrait > landscape ? FeedFormat.portrait : FeedFormat.landscape;
  }
}
