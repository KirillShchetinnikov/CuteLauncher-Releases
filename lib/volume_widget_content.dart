const volumeWidgetContentKey = 'volume_widget_content';

enum VolumeWidgetContent {
  both,
  volume,
  output;

  static VolumeWidgetContent? parse(Object? value) =>
      values.where((content) => content.name == value).firstOrNull;
}
