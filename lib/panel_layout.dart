/// Physical left/right placement shared by the home and remote panels.
class PanelLayout {
  static const buttons = [
    'settings',
    'systemSettings',
    'inputs',
    'notifications',
    'sleepTimer',
    'nightMode',
    'nas',
    'usb',
    'network',
    'vpn',
    'traffic',
    'networkSpeed',
    'system',
  ];
  static const information = ['weather', 'date', 'time'];
  // Audio stays independent of the combined clock/date/weather group.
  static const ids = [...buttons, 'audio', ...information];
  static const informationGroup = 'information';

  static List<String> clean(dynamic value) => value is List
      ? value.whereType<String>().where(ids.contains).toSet().toList()
      : <String>[];

  final List<String> left;
  final List<String> right;

  /// Collapse all information slots at the first slot, including hidden objects.
  /// Stored individual positions are kept until the user moves an object.
  (List<String>, List<String>) displayOrders(
    bool combined, {
    Set<String> excluded = const {},
  }) {
    if (!combined) {
      return (
        left.where((id) => !excluded.contains(id)).toList(),
        right.where((id) => !excluded.contains(id)).toList(),
      );
    }
    var inserted = false;
    List<String> collapse(List<String> order) {
      final result = <String>[];
      for (final id in order) {
        if (excluded.contains(id)) continue;
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
    List<String> second, {
    Set<String> excluded = const {},
  }) {
    final members = [...left, ...right]
        .where((id) => information.contains(id) && !excluded.contains(id))
        .toList();
    List<String> expand(List<String> order) => [
      for (final id in order)
        if (id == informationGroup) ...members else id,
    ];
    List<String> restore(List<String> order, List<String> original) {
      for (var i = 0; i < original.length; i++) {
        if (excluded.contains(original[i])) {
          order.insert(i.clamp(0, order.length), original[i]);
        }
      }
      return order;
    }

    return (restore(expand(first), left), restore(expand(second), right));
  }

  PanelLayout(dynamic leftValue, dynamic rightValue)
    : left = clean(leftValue),
      right = clean(rightValue) {
    right.removeWhere(left.contains);
    for (final id in ids) {
      if (!left.contains(id) && !right.contains(id)) {
        if (id == 'vpn') {
          // VPN used to be part of network; preserve that position for existing layouts.
          final group = right.contains('network') ? right : left;
          group.insert(group.indexOf('network') + 1, id);
        } else {
          (buttons.contains(id) ? left : right).add(id);
        }
      }
    }
  }
}
