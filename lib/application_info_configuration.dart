import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

const applicationInfoConfigurationKey = 'application_info_configuration';

enum ApplicationInfoGroup { home, launch, appearance, management }

enum ApplicationInfoAction {
  addToSection(ApplicationInfoGroup.home),
  reorderTile(ApplicationInfoGroup.home),
  visibility(ApplicationInfoGroup.home),
  removeFromSection(ApplicationInfoGroup.home),
  sections(ApplicationInfoGroup.home),
  open(ApplicationInfoGroup.launch),
  backgroundStartup(ApplicationInfoGroup.launch),
  rename(ApplicationInfoGroup.appearance),
  setBanner(ApplicationInfoGroup.appearance),
  clearBanner(ApplicationInfoGroup.appearance),
  checkProcess(ApplicationInfoGroup.management),
  stop(ApplicationInfoGroup.management),
  restart(ApplicationInfoGroup.management),
  androidInfo(ApplicationInfoGroup.management),
  uninstall(ApplicationInfoGroup.management);

  const ApplicationInfoAction(this.group);

  final ApplicationInfoGroup group;

  String label(AppLocalizations l) => switch (this) {
    addToSection => l.addToCategory,
    reorderTile => l.reorder,
    visibility => '${l.show} / ${l.hide}',
    removeFromSection => l.removeFromCategory,
    sections => l.appSections,
    open => l.open,
    backgroundStartup => l.backgroundStartupToggle,
    rename => l.homeAppName,
    setBanner => l.setCustomBanner,
    clearBanner => l.clearCustomBanner,
    checkProcess => l.appCheckProcess,
    stop => l.stopApp,
    restart => l.restartApp,
    androidInfo => l.appInfo,
    uninstall => l.uninstall,
  };

  IconData get icon => switch (this) {
    addToSection => Icons.add_box_outlined,
    reorderTile => Icons.open_with,
    visibility => Icons.visibility_outlined,
    removeFromSection => Icons.delete_sweep_outlined,
    sections => Icons.category_outlined,
    open => Icons.open_in_new,
    backgroundStartup => Icons.power_settings_new_rounded,
    rename => Icons.edit_outlined,
    setBanner => Icons.image_search,
    clearBanner => Icons.hide_image_outlined,
    checkProcess => Icons.refresh,
    stop => Icons.stop_circle_outlined,
    restart => Icons.restart_alt,
    androidInfo => Icons.info_outlined,
    uninstall => Icons.delete_outlined,
  };
}

class ApplicationInfoConfiguration {
  const ApplicationInfoConfiguration.defaults()
    : order = ApplicationInfoAction.values,
      hidden = const {},
      checkOnOpen = false;

  ApplicationInfoConfiguration({
    required Iterable<ApplicationInfoAction> order,
    required Iterable<ApplicationInfoAction> hidden,
    required this.checkOnOpen,
  }) : order = List.unmodifiable({...order, ...ApplicationInfoAction.values}),
       hidden = Set.unmodifiable(hidden);

  final List<ApplicationInfoAction> order;
  final Set<ApplicationInfoAction> hidden;
  final bool checkOnOpen;

  bool get usesDefaultOrder => listEquals(order, ApplicationInfoAction.values);

  ApplicationInfoConfiguration copyWith({
    Iterable<ApplicationInfoAction>? order,
    Iterable<ApplicationInfoAction>? hidden,
    bool? checkOnOpen,
  }) => ApplicationInfoConfiguration(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    checkOnOpen: checkOnOpen ?? this.checkOnOpen,
  );

  String encode() => jsonEncode({
    'order': order.map((action) => action.name).toList(),
    'hidden': [
      for (final action in ApplicationInfoAction.values)
        if (hidden.contains(action)) action.name,
    ],
    'checkOnOpen': checkOnOpen,
  });

  static ApplicationInfoConfiguration? tryDecode(Object? value) {
    if (value is! String) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final order = decoded['order'];
      final hidden = decoded['hidden'];
      final checkOnOpen = decoded['checkOnOpen'];
      if ((order != null && order is! List) ||
          (hidden != null && hidden is! List) ||
          (checkOnOpen != null && checkOnOpen is! bool)) {
        return null;
      }
      return ApplicationInfoConfiguration(
        order: _actions(order),
        hidden: _actions(hidden),
        checkOnOpen: checkOnOpen == true,
      );
    } on FormatException {
      return null;
    }
  }

  static ApplicationInfoConfiguration decode(Object? value) =>
      tryDecode(value) ?? const ApplicationInfoConfiguration.defaults();

  static Iterable<ApplicationInfoAction> _actions(Object? ids) sync* {
    if (ids is! List) return;
    final byName = {
      for (final action in ApplicationInfoAction.values) action.name: action,
    };
    for (final id in ids) {
      if (byName[id] case final action?) yield action;
    }
  }
}
