import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../home_style_availability.dart';
import '../../l10n/app_localizations.dart';

/// Supplies a compact source marker without adding a remote focus stop.
class InheritedSettingSource extends InheritedWidget {
  final String? label;
  const InheritedSettingSource({
    super.key,
    required this.label,
    required super.child,
  });

  static String? labelOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedSettingSource>()
      ?.label;

  @override
  bool updateShouldNotify(InheritedSettingSource oldWidget) =>
      label != oldWidget.label;
}

class InheritedSetting extends StatelessWidget {
  final int? categoryId;
  final String field;
  final Widget child;
  const InheritedSetting({
    super.key,
    this.categoryId,
    required this.field,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    if (categoryId == null || field == 'sectionPadding') return child;
    final service = context.watch<AppearanceService>();
    final style = service.category(categoryId!);
    final own = ownsHomeStyleField(style, field);
    final l = AppLocalizations.of(context)!;
    return InheritedSettingSource(
      label: own ? null : l.homeInherited,
      child: child,
    );
  }
}
