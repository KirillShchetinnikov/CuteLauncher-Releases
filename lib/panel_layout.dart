/// Physical left/right placement shared by the home and remote panels.
class PanelLayout {
  static const buttons = [
    'settings',
    'systemSettings',
    'inputs',
    'notifications',
    'sleepTimer',
    'nightMode',
    'network',
    'traffic',
  ];
  static const information = ['weather', 'date', 'time'];
  static const ids = [...buttons, ...information];

  static List<String> clean(dynamic value) => value is List
      ? value.whereType<String>().where(ids.contains).toSet().toList()
      : <String>[];

  final List<String> left;
  final List<String> right;
  PanelLayout(dynamic leftValue, dynamic rightValue)
    : left = clean(leftValue),
      right = clean(rightValue) {
    right.removeWhere(left.contains);
    for (final id in ids) {
      if (!left.contains(id) && !right.contains(id)) {
        (buttons.contains(id) ? left : right).add(id);
      }
    }
  }
}
