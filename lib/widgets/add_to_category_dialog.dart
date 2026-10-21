import 'launcher_dialog.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/settings_panel_style.dart';
import 'action_notice.dart';
import '../providers/settings_service.dart';

import 'package:flauncher/section_names.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../models/app.dart';
import '../models/category.dart';

import 'package:flauncher/widgets/side_panel_dialog.dart';

Future<void> showAddToCategoryDialog(
  BuildContext context,
  App application, {
  double? parentPanelWidth,
}) => _showCategoryDialog(
  context,
  application,
  parentPanelWidth: parentPanelWidth,
);

Future<void> showRemoveFromCategoryDialog(
  BuildContext context,
  App application, {
  double? parentPanelWidth,
}) => _showCategoryDialog(
  context,
  application,
  removing: true,
  parentPanelWidth: parentPanelWidth,
);

Future<void> _showCategoryDialog(
  BuildContext context,
  App application, {
  double? parentPanelWidth,
  bool removing = false,
}) async {
  final categories = context.read<AppsService>().categories;
  final eligible = removing
      ? AddToCategoryDialog.removableCategories(categories, application)
      : AddToCategoryDialog.availableCategories(categories, application);
  if (eligible.isEmpty) {
    final l = AppLocalizations.of(context)!;
    showActionNotice(
      context,
      removing ? l.noRemovableCategories : l.noAvailableCategories,
    );
    return;
  }
  await showLauncherDialog<void>(
    context: context,
    parentPanelWidth: parentPanelWidth,
    onRight: parentPanelWidth == null
        ? null
        : context.read<SettingsService?>()?.settingsMenuOnRight ?? false,
    builder: (_) => AddToCategoryDialog(
      application,
      removing: removing,
      asSidePanel: parentPanelWidth != null,
    ),
  );
}

class AddToCategoryDialog extends StatelessWidget {
  final App selectedApplication;
  final bool asSidePanel;
  final bool removing;

  const AddToCategoryDialog(
    this.selectedApplication, {
    super.key,
    this.asSidePanel = false,
    this.removing = false,
  });

  static bool _contains(Category category, App app) =>
      app.categoryOrders.containsKey(category.id) ||
      category.applications.any((item) => item.packageName == app.packageName);

  static List<Category> availableCategories(
    List<Category> categories,
    App app,
  ) => categories
      .where((category) => !category.isAutomatic && !_contains(category, app))
      .toList();

  static List<Category> removableCategories(
    List<Category> categories,
    App app,
  ) => categories
      .where((category) => !category.isAutomatic && _contains(category, app))
      .toList();

  @override
  Widget build(BuildContext context) =>
      SettingsPanelStyle(builder: _buildPanel);

  Widget _buildPanel(BuildContext context) => Selector<AppsService, List<Category>>(
    selector: (_, appsService) => removing
        ? removableCategories(appsService.categories, selectedApplication)
        : availableCategories(appsService.categories, selectedApplication),
    builder: (context, categories, _) {
      AppLocalizations localizations = AppLocalizations.of(context)!;

      final choices = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return FocusableSettingsTile(
            autofocus: index == 0,
            title: Text(localizedSectionName(category.name, localizations)),
            onPressed: () async {
              final apps = context.read<AppsService>();
              if (removing) {
                await apps.removeFromCategory(selectedApplication, category);
              } else {
                await apps.addToCategory(selectedApplication, category);
              }
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      );
      if (!asSidePanel && (context
              .dependOnInheritedWidgetOfExactType<LauncherDialogArea>()
              ?.settingsOpen ??
          false)) {
        return LauncherAlertDialog(
          title: Text(removing ? localizations.removeFromCategory : localizations.withEllipsisAddTo),
          content: choices,
          actions: [
            LauncherDialogButton(
              onPressed: () => Navigator.pop(context),
              isCancel: true,
              child: Text(localizations.cancel),
            ),
          ],
        );
      }
      return SidePanelDialog(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              removing ? localizations.removeFromCategory : localizations.withEllipsisAddTo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Flexible(child: SingleChildScrollView(child: choices)),
          ],
        ),
      );
    },
  );
}
