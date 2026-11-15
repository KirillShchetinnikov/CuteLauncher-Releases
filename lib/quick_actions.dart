const quickActionsVisibleKey = 'show_quick_actions_in_status_bar';
const quickActionsItemsKey = 'quick_actions_items';
const quickActionsOrderKey = 'quick_actions_order';

/// Stored IDs remain stable across translations and changes to the menu.
enum QuickAction {
  sleep,
  shutdown,
  reboot,
  screensaver,
  wallpaper;

  static List<QuickAction> fromSettings(Object? value) => value is List
      ? values.where((action) => value.contains(action.name)).toList()
      : values;

  static List<QuickAction> orderFromSettings(Object? value) {
    final order = <QuickAction>{};
    if (value is List) {
      final byName = {for (final action in values) action.name: action};
      for (final id in value) {
        if (byName[id] case final action?) order.add(action);
      }
    }
    return (order..addAll(values)).toList();
  }
}
