import 'settings_text_tile.dart';
import 'settings_value_stepper.dart';
import 'settings_choice_tile.dart';
import 'settings_route.dart';
import 'settings_page_layout.dart';
import 'settings_help.dart';
import '../../providers/appearance_service.dart';
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

import 'package:flauncher/section_names.dart';
import 'dart:async';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../models/category.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'category_appearance_page.dart';

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

class _SettingsState extends ChangeNotifier
{
  bool _changed;
  bool _creating;
  bool _deleted;
  bool _valid;
  LauncherSection? _section;
  LauncherSectionType _sectionType;

  void Function()? onSave;

  bool get changed => _changed;
  bool get creating => _creating;
  bool get deleted => _deleted;
  bool get valid => _valid;
  LauncherSection? get launcherSection => _section;
  LauncherSectionType get sectionType => _sectionType;

  _SettingsState(AppsService appsService, int? sectionIndex):
      _changed = false,
      _creating = false,
      _deleted = false,
      _valid = false,
      _sectionType = LauncherSectionType.Category
  {
    LauncherSection? launcherSection;
    List<LauncherSection> sections = appsService.launcherSections;
    if (sectionIndex != null && sectionIndex < sections.length) {
      launcherSection = sections[sectionIndex];
    }

    setLauncherSection(launcherSection, shouldNotifyListeners: false);
  }

  void setDeleted() {
    _deleted = true;
  }

  void setFlags(bool valid, bool changed)
  {
    if (_valid != valid || _changed != changed) {
      _valid = valid;
      _changed = changed;

      notifyListeners();
    }
  }

  void setLauncherSection(LauncherSection? section, {bool shouldNotifyListeners = true})
  {
    _section = section;

    _changed = false;
    _creating = false;
    _valid = false;
    _sectionType = LauncherSectionType.Category;

    if (section == null) {
      _creating = true;
    }
    else if (section is LauncherSpacer) {
      _sectionType = LauncherSectionType.Spacer;
    }

    _valid = false;
    _changed = creating;

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void setSectionType(LauncherSectionType sectionType)
  {
    assert(_creating);

    _changed = false;
    _valid = false;

    if (_sectionType != sectionType) {
      _sectionType = sectionType;

      if (sectionType == LauncherSectionType.Spacer) {
        _changed = true;
        _valid = true;
      }

      notifyListeners();
    }
  }
}

class LauncherSectionPanelPage extends StatelessWidget
{
  static const String routeName = "section_panel";

  final int? sectionIndex;

  const LauncherSectionPanelPage({super.key, this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) {
        AppsService service = context.read();
        return _SettingsState(service, sectionIndex);
      },
      builder: (context, _) => Selector<_SettingsState, LauncherSectionType>(
        selector: (_, state) => state.sectionType,
        builder: (_, sectionType, _)  {
          _SettingsState state = context.read();
          LauncherSection? launcherSection = state.launcherSection;

          if (state.deleted) {
            return Container();
          }

          bool creating = state.creating;
          Widget sectionSpecificSettings;

          if (sectionType == LauncherSectionType.Category) {
            sectionSpecificSettings = _CategorySettings(
              category: launcherSection as Category?,
            );
          }
          else {
            sectionSpecificSettings = _LauncherSpacerSettings(
                spacer: launcherSection as LauncherSpacer?
            );
          }

          String title = localizations.newSection;
          if (!creating) {
            title = localizations.modifySection;
          }

          return SettingsPageLayout(
            title: Text(title),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (creating) ...[
                    _listTile(
                      context,
                      Text(localizations.type),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: _SettingsChoice<LauncherSectionType>(
                          autofocus: true,
                          initialValue: sectionType,
                          onChanged: (value) {
                            if (value != null) {
                              state.setSectionType(value);
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: LauncherSectionType.Category,
                              child: Text(
                                localizations.category,

                              ),
                            ),
                            DropdownMenuItem(
                              value: LauncherSectionType.Spacer,
                              child: Text(
                                localizations.spacer,

                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                  ],
                  sectionSpecificSettings,
                  Divider(),
                  if (creating) Selector<_SettingsState, bool>(
                    selector: (context, state) => (state.valid && state.changed),
                    builder: (context, canSave, _) {
                      void Function()? onSavePressed;
                      if (canSave) {
                        onSavePressed = () {
                          if (state.onSave != null) {
                            state.onSave!();
                          }
                        };
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: FocusableSettingsTile(onPressed: onSavePressed,
                          leading: const Icon(Icons.save_outlined),
                          title: Text(localizations.save), enabled: canSave,
                        ),
                      );
                    },
                  ),
                  if (!creating && launcherSection is Category)
                    Consumer<AppsService>(
                      builder: (context, service, _) {
                        final category = service.launcherSections
                            .whereType<Category>()
                            .firstWhere((c) => c.id == launcherSection.id);
                        final canHide =
                            !category.visible ||
                            service.launcherSections
                                    .whereType<Category>()
                                    .where((c) => c.visible)
                                    .length >
                                1;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [RoundedSwitchListTile(
                          enabled: canHide,
                          value: category.visible,
                          onChanged: (value) =>
                              service.setCategoryVisible(category.id, value),
                          title: Text(localizations.categoryVisible),
                        ),
                        if (!canHide)
                          SettingsHelp(text: localizations.categoryLastVisibleHint),
                        ],
                        );
                      },
                    ),
                  if (!creating &&
                      !(state.launcherSection is Category &&
                        (state.launcherSection as Category).isSystem))
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: FocusableSettingsTile(onPressed:
                            state.launcherSection is Category &&
                                ((state.launcherSection as Category).isSystem ||
                                    context
                                            .read<AppsService>()
                                            .launcherSections
                                            .whereType<Category>()
                                            .length <=
                                        1 ||
                                    ((state.launcherSection as Category).visible &&
                                        context
                                                .read<AppsService>()
                                                .launcherSections
                                                .whereType<Category>()
                                                .where((c) => c.visible)
                                                .length <=
                                            1))
                            ? null
                            : () async {
                                await context.read<AppsService>().deleteSection(
                                  sectionIndex!,
                                );
                                state.setDeleted();
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                        leading: const Icon(Icons.delete_outline),
                        title: Text(localizations.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      )
    );
  }
}

class _CategorySettings extends StatefulWidget
{
  final Category? category;

  const _CategorySettings({
    this.category
  });

  @override
  State<StatefulWidget> createState() => _CategorySettingsState();
}

class _CategorySettingsState extends State<_CategorySettings>
{

  
  late final TextEditingController _nameController;
  

  CategorySort _categorySort;
  CategoryType _categoryType;
  int _columnsCount;
  int _rowHeight;
  String _name;

  late Category? _category;

  late bool _creating;

  _CategorySettingsState():

        _categorySort = Category.Sort,
        _categoryType = Category.Type,
        _columnsCount = Category.ColumnsCount,
        _rowHeight = Category.RowHeight,
        _name = "";

  @override
  void dispose() {
    super.dispose();

    _nameController.dispose();

  }

  @override
  void initState() {
    super.initState();

    _category = widget.category;
    _creating = _category == null;

    if (!_creating) {
      _name = _category!.name;
      _categorySort = _category!.sort;
      _categoryType = _category!.type;
      _columnsCount = _category!.columnsCount;
      _rowHeight = _category!.rowHeight;
    }

    _nameController = TextEditingController(text: _name);

    _SettingsState state = context.read();
    state.onSave = _save;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final namePresets = [
      ...sectionNamePresets,
      if (_category?.isSystem == true && !sectionNamePresets.contains(_category!.name)) _category!.name,
    ];
    
    return PopScope(
      canPop: true,
      child: Column(
        children: [
          _listTile(
            context,
            Text(localizations.name),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: _SettingsChoice<String>(
              autofocus: !_creating,


              initialValue: namePresets.contains(_name) ? _name : 'Custom...',
              hint: Text(_name.isEmpty ? localizedSectionName('Custom...', localizations) : localizedSectionName(_name, localizations)),
              onChanged: (value) {
                setState(() {
                  if (value == 'Custom...') {
                    _name = '';
                    _nameController.text = '';
                  } else if (value != null) {
                    _name = value;
                    _nameController.text = value;
                  }
                });
                _notifyChange();
              },
              items: namePresets.map((name) => DropdownMenuItem(
                value: name,
                child: Text(localizedSectionName(name, localizations)),
              )).toList(),
            )
          )
        ),
        if (!namePresets.contains(_name) || _name.isEmpty)
          SettingsTextTile(
            title: localizations.customName, value: _name, maxLength: 256,
            onChanged: (value) {
              setState(() { _name = value; _nameController.text = value; });
              _notifyChange();
            },
          ),
        _listTile(
          context,
          Text(localizations.sort),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: _SettingsChoice<CategorySort>(
              initialValue: _categorySort,
              onChanged: (value) {
                setState(() {
                  _categorySort = value!;
                });
                _notifyChange();
              },
              items: [
                DropdownMenuItem(
                  value: CategorySort.alphabetical,
                  child: Text(localizations.alphabetical),
                ),
                DropdownMenuItem(
                  value: CategorySort.manual,
                  child: Text(localizations.manual),
                ),
                DropdownMenuItem(
                  value: CategorySort.mostUsed,
                  child: Text(localizations.mostUsed),
                ),
                DropdownMenuItem(
                  value: CategorySort.lastUsed,
                  child: Text(AppLocalizations.of(context)!.lastUsed),
                )
              ]
            )
          )
        ),
        if (_creating)
        _listTile(
          context,
          Text(localizations.layout),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: _SettingsChoice<CategoryType>(
              initialValue: _categoryType,
              onChanged: (value) {
                setState(() {
                  _categoryType = value!;
                });
                _notifyChange();
              },


              items: [
                DropdownMenuItem(
                  value: CategoryType.row,
                  child: Text(localizations.row)
                ),
                DropdownMenuItem(
                  value: CategoryType.grid,
                  child: Text(localizations.grid)
                )
              ]
            )
          )
        ),
        if (!_creating)
          FocusableSettingsTile(
            title: Text(localizations.categoryAppearance),
            leading: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.of(context).push(SettingsRoute<void>(
              builder: (_) => CategoryAppearancePage(categoryId: _category!.id))),
          ),
      ],
    ),
  );
}

  void _notifyChange()
  {

    String initialName = "";
    CategorySort initialSort = Category.Sort;
    CategoryType initialType = Category.Type;
    int initialColumnsCount = Category.ColumnsCount;
    int initialRowHeight = Category.RowHeight;
    if (_category != null) {
      initialName = _category!.name;
      initialSort = _category!.sort;
      initialType = _category!.type;
      initialColumnsCount = _category!.columnsCount;
      initialRowHeight = _category!.rowHeight;
    }

    bool dirty = initialSort != _categorySort || initialType != _categoryType
        || initialColumnsCount != _columnsCount
        || initialRowHeight != _rowHeight || initialName != _name ;

    _SettingsState state = context.read();
    state.setFlags(_name.trim().isNotEmpty, dirty);
    if (!_creating && _name.trim().isNotEmpty && dirty) {
      unawaited(_save());
    }
  }

  Future<void> _save() async
  {
    final AppsService service = context.read();
    if (_creating) {
      int categoryId = await service.addCategory(_name, sort: _categorySort, type: _categoryType,
          columnsCount: _columnsCount, rowHeight: _rowHeight
      );

      if (mounted) {
        final appearance = context.read<AppearanceService?>();
        await appearance?.setCategory(categoryId, 'layout', _categoryType == CategoryType.row ? 'row' : 'grid');
        await appearance?.setCategory(categoryId, 'columns', _categoryType == CategoryType.row ? 0 : 6);
        await appearance?.setCategory(categoryId, 'maxRows', _categoryType == CategoryType.row ? 0 : 3);
      }

      if (!mounted || !context.mounted) return;
      Navigator.of(context).pop(service.launcherSections.firstWhere((s) => s is Category && s.id == categoryId));
    }
    else {
      await service.updateCategory(_category!.id, _name, _categorySort,
          _categoryType, _columnsCount, _rowHeight
      );

    }
  }
}

class _LauncherSpacerSettings extends StatefulWidget
{
  final LauncherSpacer? spacer;

  const _LauncherSpacerSettings({this.spacer});

  @override
  State<StatefulWidget> createState() => _LauncherSpacerSettingsState();
}

class _LauncherSpacerSettingsState extends State<_LauncherSpacerSettings>
{
  int _numberValue;
  LauncherSpacer? _spacer;

  late bool _creating;
  
  // Need preset values for the dropdown
  final List<int> _spacerHeightPresets = [10, 20, 30, 40, 50, 75, 100, 125, 150, 175, 200, 250];

  _LauncherSpacerSettingsState():
    _numberValue = 10;

  @override
  void initState() {
    super.initState();

    _spacer = widget.spacer;
    _creating = _spacer == null;

    int height = 10;
    if (_spacer != null) {
      height = _spacer!.height;
    }

    _numberValue = height;
    
    // Ensure the current value is in our presets, if not add it
    if (!_spacerHeightPresets.contains(_numberValue)) {
      _spacerHeightPresets.add(_numberValue);
      _spacerHeightPresets.sort();
    }
    
    context.read<_SettingsState>().onSave = _save;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return _listTile(
      context,
      Text(localizations.height),
      Padding(
        padding: EdgeInsets.only(top: 4),
        child: _SettingsChoice<int>(
          autofocus: !_creating,
          initialValue: _numberValue,
          onChanged: (value) {
            setState(() {
              _numberValue = value!;
            });
            _notifyChange();
          },
          items: _spacerHeightPresets.map((height) {
            return DropdownMenuItem<int>(
              value: height,
              child: Text(height.toString()),
            );
          }).toList(),
        )
      )
    );
  }

  void _notifyChange()
  {
    context.read<_SettingsState>().setFlags(true, _numberValue != _spacer?.height);
    if (!_creating && _numberValue != _spacer?.height) unawaited(_save());
  }

  Future<void> _save() async
  {
    AppsService service = context.read();
    if (_creating) {
      await service.addSpacer(_numberValue);

      if (!mounted || !context.mounted) return;
      Navigator.of(context).pop(service.launcherSections.last);
    }
    else {
      assert(_spacer != null);
      await service.updateSpacerHeight(_spacer!, _numberValue);
    }
  }
}

Widget _listTile(BuildContext context, Widget title, Widget subtitle) {
  final child = subtitle is Padding ? subtitle.child! : subtitle;
  return _ChoiceLabel(title: title, child: child);
}

class _ChoiceLabel extends InheritedWidget {
  final Widget title;
  const _ChoiceLabel({required this.title, required super.child});
  @override
  bool updateShouldNotify(_ChoiceLabel oldWidget) => title != oldWidget.title;
}

class _SettingsChoice<T> extends StatelessWidget {
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final bool autofocus;
  final Widget? hint;
  const _SettingsChoice({this.hint, this.initialValue, this.items,
    this.onChanged, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final title = context.dependOnInheritedWidgetOfExactType<_ChoiceLabel>()!.title as Text;
    final choices = items ?? <DropdownMenuItem<T>>[];
    if (initialValue is num && choices.every((item) => item.value is num)) {
      return SettingsValueStepper(title: title.data ?? '',
        options: choices.map((item) => item.value).toList(), value: initialValue,
        label: (v) => '$v', autofocus: autofocus, enabled: onChanged != null,
        onChanged: (v) => onChanged?.call(v as T));
    }
    return SettingsChoiceTile<T?>(title: title.data ?? '', value: initialValue,
      options: choices.map((item) => item.value).toList(),
      valueLabel: hint is Text ? (hint as Text).data : null,
      label: (v) {
        final child = choices.where((item) => item.value == v).firstOrNull?.child;
        return child is Text ? child.data ?? '' : '$v';
      },
      autofocus: autofocus, enabled: onChanged != null,
      onChanged: (v) => onChanged?.call(v));
  }
}
