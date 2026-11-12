const volumeOverlayPositionKey = 'volume_overlay_position';

enum OverlayPosition {
  widget,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  static OverlayPosition? parse(Object? value) =>
      values.where((position) => position.name == value).firstOrNull;
}
