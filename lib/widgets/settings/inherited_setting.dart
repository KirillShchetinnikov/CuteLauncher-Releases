import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../home_style_availability.dart';
import '../../l10n/app_localizations.dart';
import 'focusable_settings_tile.dart';

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
    if (categoryId == null) return child;
    final service = context.watch<AppearanceService>();
    final style = service.category(categoryId!);
    final own = ownsHomeStyleField(style, field);
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (own)
          FocusableSettingsTile(
            title: Text(l.homeOwnReset),
            leading: const Icon(Icons.restore),
            onPressed: () => service.inheritField(categoryId!, field),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, bottom: 8),
            child: Text(
              l.homeInherited,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
