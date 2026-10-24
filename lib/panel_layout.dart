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
  static const informationGroup = 'information';

  static List<String> clean(dynamic value) => value is List
      ? value.whereType<String>().where(ids.contains).toSet().toList()
      : <String>[];

  final List<String> left;
  final List<String> right;

  /// Collapse all information slots at the first slot, including hidden objects.
  /// Stored individual positions are kept until the user moves an object.
  (List<String>, List<String>) displayOrders(bool combined) {
    if (!combined) return ([...left], [...right]);
    var inserted = false;
    List<String> collapse(List<String> order) {
      final result = <String>[];
      for (final id in order) {
        if (!information.contains(id)) {
          result.add(id);
        } else if (!inserted) {
          result.add(informationGroup);
          inserted = true;
        }
      }
      return result;
    }

    return (collapse(left), collapse(right));
  }

  (List<String>, List<String>) expandOrders(
    List<String> first,
    List<String> second,
  ) {
    final members = [...left, ...right].where(information.contains).toList();
    List<String> expand(List<String> order) => [
      for (final id in order)
        if (id == informationGroup) ...members else id,
    ];
    return (expand(first), expand(second));
  }

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
