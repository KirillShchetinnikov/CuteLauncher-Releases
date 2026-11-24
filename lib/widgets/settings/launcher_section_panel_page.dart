/*
 * FLauncher
 * Copyright (C) 2024 Oscar Rojas 
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/appearance_service.dart';
import '../../providers/apps_service.dart';
import '../../section_names.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../menu_header_action.dart';
import '../rename_category_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'app_channels_order_page.dart';
import 'app_channels_settings_page.dart';
import 'category_appearance_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_choice_dialog.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_text_tile.dart';
import 'settings_value_stepper.dart';

// Section name presets for TV remote-friendly selection
const List<String> sectionNamePresets = [
  'Custom...',
  'Movies & Shows',
  'Music',
  'Games',
  'Entertainment',
  'Live TV',
  'Sports',
  'News',
  'Tools',
];

class LauncherSectionPanelPage extends StatefulWidget {
  static const String routeName = 'section_panel';
  final int? sectionIndex;
  const LauncherSectionPanelPage({super.key, this.sectionIndex});

  @override
  State<LauncherSectionPanelPage> createState() =>
      _LauncherSectionPanelPageState();
}

class _LauncherSectionPanelPageState extends State<LauncherSectionPanelPage> {
  final _entryFocus = FocusNode();
  LauncherSection? _opened;
  var _sectionType = LauncherSectionType.Category;
  var _name = '';
  var _sort = Category.Sort;
  var _layout = Category.Type;
  var _visible = true;
  var _height = 10;
  var _saving = false;

  bool get _creating => widget.sectionIndex == null;

  @override
  void initState() {
    super.initState();
    final index = widget.sectionIndex;
    if (index == null) return;
    final sections = context.read<AppsService>().launcherSections;
    if (index < 0 || index >= sections.length) return;
    _opened = sections[index];
    if (_opened is LauncherSpacer) {
      _sectionType = LauncherSectionType.Spacer;
    }
  }

  @override
  void dispose() {
    _entryFocus.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    final service = context.read<AppsService>();
    setState(() => _saving = true);
    try {
      final LauncherSection created;
      if (_sectionType == LauncherSectionType.Spacer) {
        created = await service.addSpacer(_height);
      } else {
        if (_name.trim().isEmpty) return;
        final id = await service.addCategory(
          _name,
          sort: _sort,
          type: _layout,
          visible: _visible,
          initializeLayout: true,
        );
        if (id < 0) throw StateError('Section creation failed');
        created = service.launcherSections.whereType<Category>().firstWhere(
          (c) => c.id == id,
        );
      }
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(created);
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError() {
    if (mounted) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.appError,
        error: true,
      );
    }
  }

  Future<void> _persist(Future<void> write) async {
    try {
      await write;
    } catch (_) {
      _showError();
    }
  }

  Future<void> _rename(Category category) async {
    final l = AppLocalizations.of(context)!;
    final presets = [
      ...sectionNamePresets,
      if (category.isSystem && !sectionNamePresets.contains(category.name))
        category.name,
    ];
    final choice = await showLauncherDialog<String>(
      context: context,
      builder: (dialog) => SettingsChoiceDialog<String>(
        title: Text(l.renameCategory),
        value: presets.contains(category.name) ? category.name : 'Custom...',
        options: presets,
        optionBuilder: (name) => Text(localizedSectionName(name, l)),
        onSelected: (name) => Navigator.pop(dialog, name),
      ),
    );
    if (!mounted || choice == null) return;
    final displayedName = localizedSectionName(category.name, l);
    final name = choice == 'Custom...'
        ? await showLauncherDialog<String>(
            context: context,
            builder: (_) => AddCategoryDialog(initialValue: displayedName),
          )
        : choice;
    if (!mounted ||
        name == null ||
        name.trim().isEmpty ||
        name == category.name ||
        (choice == 'Custom...' && name == displayedName)) {
      return;
    }
    await _persist(context.read<AppsService>().renameCategory(category, name));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppsService>();
    final sections = service.launcherSections;
    final section = _creating
        ? null
        : sections
              .where(
                (s) =>
                    s.runtimeType == _opened.runtimeType && s.id == _opened?.id,
              )
              .firstOrNull;
    final category = section is Category ? section : null;
    final spacer = section is LauncherSpacer ? section : null;
    final feedGroup = category?.isAppChannels == true;
    final visibleCount = sections
        .whereType<Category>()
        .where((c) => c.visible)
        .length;
    final canHide = category == null
        ? visibleCount > 0
        : !category.visible || visibleCount > 1;
    final isSpacer = _sectionType == LauncherSectionType.Spacer;
    final valid = isSpacer || _name.trim().isNotEmpty;
    final customName =
        !sectionNamePresets.contains(_name) || _name == 'Custom...';
    final appearance = context.watch<AppearanceService?>();
    final effectiveLayout = category == null
        ? _layout.name
        : appearance
                  ?.category(category.id)
                  .resolvedLayout(category.type == CategoryType.row) ??
              category.type.name;
    final height = spacer?.height ?? _height;
    const heights = [10, 20, 30, 40, 50, 75, 100, 125, 150, 175, 200, 250];

    final title = switch (section) {
      Category() when feedGroup => l.appChannelsTitle,
      Category() when section.name.trim().isEmpty => l.category,
      Category() => localizedSectionName(section.name, l),
      LauncherSpacer() => l.spacer,
      _ => _creating ? l.newSection : l.modifySection,
    };
    final heading = Text(title, maxLines: 2, overflow: TextOverflow.ellipsis);
    return SettingsPageLayout(
      title: category != null && !feedGroup
          ? Row(
              children: [
                Expanded(child: heading),
                MenuHeaderAction(
                  focusNode: _entryFocus,
                  tooltip: l.renameCategory,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _rename(category),
                ),
              ],
            )
          : heading,
      initialFocus: category != null ? _entryFocus : null,
      child: !_creating && section == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_creating)
                    SettingsChoiceTile<LauncherSectionType>(
                      title: l.type,
                      value: _sectionType,
                      options: LauncherSectionType.values,
                      label: (type) => type == LauncherSectionType.Spacer
                          ? l.spacer
                          : l.category,
                      onChanged: (type) => setState(() => _sectionType = type),
                    ),
                  if (isSpacer)
                    SettingsValueStepper(
                      title: l.height,
                      value: height,
                      options: heights.contains(height)
                          ? heights
                          : ([...heights, height]..sort()),
                      label: (value) => '$value',
                      onChanged: (value) {
                        if (spacer == null) {
                          setState(() => _height = value as int);
                        } else {
                          _persist(
                            service.updateSpacerHeight(spacer, value as int),
                          );
                        }
                      },
                    )
                  else ...[
                    if (_creating) ...[
                      SettingsChoiceTile<String>(
                        title: l.name,
                        value: customName ? 'Custom...' : _name,
                        valueLabel: _name.isEmpty
                            ? l.customSectionName
                            : localizedSectionName(_name, l),
                        options: sectionNamePresets,
                        label: (name) => localizedSectionName(name, l),
                        onChanged: (name) {
                          if (name != 'Custom...') {
                            setState(() => _name = name);
                          } else if (!customName) {
                            setState(() => _name = '');
                          }
                        },
                      ),
                      if (customName)
                        SettingsTextTile(
                          title: l.customName,
                          value: _name,
                          maxLength: 256,
                          onChanged: (value) => setState(() => _name = value),
                        ),
                    ],
                    RoundedSwitchListTile(
                      title: Text(l.categoryVisible),
                      enabled: canHide,
                      value: category?.visible ?? (_visible || !canHide),
                      onChanged: (value) {
                        if (category == null) {
                          setState(() => _visible = value);
                        } else {
                          _persist(
                            service.setCategoryVisible(category.id, value),
                          );
                        }
                      },
                    ),
                    if (!canHide)
                      SettingsMessage(text: l.categoryLastVisibleHint),
                    if (feedGroup) ...[
                      FocusableSettingsTile(
                        focusNode: _entryFocus,
                        title: Text(l.feedsAndOrder),
                        leading: const Icon(Icons.view_list_outlined),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppChannelsOrderPage.routeName,
                        ),
                      ),
                      FocusableSettingsTile(
                        title: Text(l.appChannelsSectionSettings),
                        leading: const Icon(Icons.tune),
                        onPressed: () => Navigator.of(context).push(
                          SettingsRoute<void>(
                            builder: (_) =>
                                const AppChannelsSectionSettingsPage(),
                          ),
                        ),
                      ),
                    ] else ...[
                      SettingsChoiceTile<CategorySort>(
                        title: l.sort,
                        value: category?.sort ?? _sort,
                        options: const [
                          CategorySort.alphabetical,
                          CategorySort.manual,
                          CategorySort.mostUsed,
                          CategorySort.lastUsed,
                        ],
                        label: (sort) => switch (sort) {
                          CategorySort.alphabetical => l.alphabetical,
                          CategorySort.manual => l.manual,
                          CategorySort.mostUsed => l.mostUsed,
                          CategorySort.lastUsed => l.lastUsed,
                        },
                        onChanged: (sort) {
                          if (category == null) {
                            setState(() => _sort = sort);
                          } else {
                            _persist(service.setCategorySort(category, sort));
                          }
                        },
                      ),
                      SectionLayoutTile(
                        mode: effectiveLayout,
                        onChanged: (mode) {
                          final type = mode == 'grid'
                              ? CategoryType.grid
                              : CategoryType.row;
                          if (category == null) {
                            setState(() => _layout = type);
                          } else if (appearance != null) {
                            _persist(
                              appearance.setCategory(
                                category.id,
                                'layout',
                                mode,
                              ),
                            );
                          } else {
                            _persist(service.setCategoryType(category, type));
                          }
                        },
                      ),
                    ],
                    if (category != null)
                      FocusableSettingsTile(
                        title: Text(l.categoryAppearance),
                        leading: const Icon(Icons.palette_outlined),
                        onPressed: () => Navigator.of(context).push(
                          SettingsRoute<void>(
                            builder: (_) =>
                                CategoryAppearancePage(categoryId: category.id),
                          ),
                        ),
                      ),
                  ],
                  if (_creating) ...[
                    const Divider(),
                    FocusableSettingsTile(
                      title: Text(l.save),
                      leading: const Icon(Icons.save_outlined),
                      enabled: valid,
                      busy: _saving,
                      onPressed: valid && !_saving ? _create : null,
                    ),
                  ] else if (section != null && category?.isSystem != true) ...[
                    const Divider(),
                    _DeleteSectionTile(
                      section: section,
                      enabled:
                          category == null ||
                          (sections.whereType<Category>().length > 1 &&
                              canHide),
                      onDeleted: () => Navigator.of(context).pop(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DeleteSectionTile extends StatefulWidget {
  const _DeleteSectionTile({
    required this.section,
    required this.enabled,
    required this.onDeleted,
  });
  final LauncherSection section;
  final bool enabled;
  final VoidCallback onDeleted;
  @override
  State<_DeleteSectionTile> createState() => _DeleteSectionTileState();
}

class _DeleteSectionTileState extends State<_DeleteSectionTile> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_busy || !widget.enabled) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final l = AppLocalizations.of(context)!;
    try {
      final name = widget.section is Category
          ? (widget.section as Category).name
          : l.spacer;
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text('${l.delete}: $name'),
          content: Text(l.sectionDeleteConfirm),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              isCancel: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.delete),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final service = context.read<AppsService>();
      // Resolve again after the dialog: a refreshed catalogue may change order.
      final index = service.launcherSections.indexWhere(
        (s) =>
            s.runtimeType == widget.section.runtimeType &&
            s.id == widget.section.id,
      );
      if (index < 0) return;
      await service.deleteSection(index);
      if (mounted) widget.onDeleted();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableSettingsTile(
          enabled: widget.enabled,
          busy: _busy,
          leading: const Icon(Icons.delete_outline),
          title: Text(
            l.delete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: _delete,
        ),
        if (_busy) Text(l.loading),
        if (_failed)
          Text(
            l.sectionDeleteFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
