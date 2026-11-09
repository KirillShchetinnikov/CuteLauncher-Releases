import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'ensure_visible.dart';

Widget categoryContainerEmptyState(
  BuildContext context, {
  FocusNode? focusNode,
  ValueChanged<bool>? onFocusChange,
  bool scrollOnFocus = true,
}) {
  AppLocalizations localizations = AppLocalizations.of(context)!;

  final tile = Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            focusNode: focusNode,
            onFocusChange: onFocusChange,
            onTap: () => showLauncherDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (_) => SettingsPanel(
                initialRoute: LauncherSectionsPanelPage.routeName,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  localizations.textEmptyCategory,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return SizedBox(
    height: 110,
    child: scrollOnFocus ? EnsureVisible(alignment: 0.5, child: tile) : tile,
  );
}
