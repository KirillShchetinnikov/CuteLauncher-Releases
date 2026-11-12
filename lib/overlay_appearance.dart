const volumeOverlayAppearanceKey = 'volume_overlay_appearance';

enum OverlayAppearance {
  topPanel,
  dark;

  static OverlayAppearance? parse(Object? value) =>
      values.where((appearance) => appearance.name == value).firstOrNull;
}
