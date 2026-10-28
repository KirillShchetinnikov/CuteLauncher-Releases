import 'settings_help.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_page_layout.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../models/category.dart';

class LauncherSectionsPanelPage extends StatefulWidget {
  static const String routeName = "launcher_sections_panel";

  const LauncherSectionsPanelPage({super.key});

  @override
  State<LauncherSectionsPanelPage> createState() =>
      _LauncherSectionsPanelPageState();
}

class _LauncherSectionsPanelPageState extends State<LauncherSectionsPanelPage> {
  LauncherSection? _movingSection;
  late AppsService _appsService;
  final Map<Object, FocusNode> _focusNodes = {};
  DateTime? _lastMoveTime;
  bool _moveBusy = false;
  final _addFocusNode = FocusNode();
  final _resetFocusNode = FocusNode();
  bool _resetBusy = false;
  final ContinueWatchingSection _continueWatchingSection =
      ContinueWatchingSection();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appsService = Provider.of<AppsService>(context, listen: false);
  }

  FocusNode _getFocusNode(LauncherSection section) {
    final key = (section.runtimeType, section.id);
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  @override
  void dispose() {
    _appsService.persistSectionsOrder();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _addFocusNode.dispose();
    _resetFocusNode.dispose();
    super.dispose();
  }

  List<LauncherSection> _getDisplaySections(
    List<LauncherSection> appSections,
    SettingsService? settingsService,
  ) {
    final list = appSections.where((s) => s is! Category || s.visible).toList();
    if (settingsService != null && settingsService.showContinueWatching) {
      final cwOrder = settingsService.continueWatchingOrder.clamp(
        0,
        list.length,
      );
      _continueWatchingSection.order = cwOrder;
      list.insert(cwOrder, _continueWatchingSection);
    }
    return list;
  }

  List<LauncherSection> _hiddenSections(SettingsService? settings) {
    final list = _appsService.launcherSections
        .whereType<Category>()
        .where((c) => !c.visible)
        .cast<LauncherSection>()
        .toList();
    if (settings != null && !settings.showContinueWatching) {
      list.insert(
        settings.continueWatchingOrder.clamp(0, list.length),
        _continueWatchingSection,
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final settingsService = Provider.of<SettingsService?>(context);

    return SettingsPageLayout(
      title: Text(
        localizations.launcherSections,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: Consumer<AppsService>(
        builder: (_, service, _) {
          final displaySections = _getDisplaySections(
            service.launcherSections,
            settingsService,
          );
          final hidden = _hiddenSections(settingsService);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(localizations.visibleCategories),
                for (var i = 0; i < displaySections.length; i++)
                  _section(
                    context,
                    displaySections[i],
                    settingsService,
                    autofocus: i == 0,
                  ),
                Text(localizations.hiddenCategories),
                for (var i = 0; i < hidden.length; i++)
                  _section(context, hidden[i], settingsService),
                const Divider(),
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      final sections = _navigationSections(settingsService);
                      if (sections.isNotEmpty) {
                        _getFocusNode(sections.last).requestFocus();
                      }
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      _resetFocusNode.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: FocusableSettingsTile(
                    focusNode: _addFocusNode,
                    leading: const Icon(Icons.add),
                    title: Text(localizations.addSection),
                    onPressed: () => _openEditor(),
                  ),
                ),
                FocusableSettingsTile(
                  focusNode: _resetFocusNode,
                  leading: const Icon(Icons.restore),
                  title: Text(localizations.resetSections),
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _addFocusNode.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  onPressed: _resetBusy
                      ? null
                      : () => _resetSections(settingsService),
                ),
                SettingsHelp(text: '${localizations.reorderSectionsHint}\n\n${localizations.sectionRulesHelp}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context,
    LauncherSection section,
    SettingsService? settingsService, {
    bool autofocus = false,
  }) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    String title = localizations.spacer;
    if (section is ContinueWatchingSection) {
      title = localizations.continueWatching;
    } else if (section is Category) {
      title = localizedSectionName(section.name, AppLocalizations.of(context)!);

      if (title == localizations.spacer) {
        title = localizations.disambiguateCategoryTitle(title);
      }
    }

    final bool isMoving =
        _movingSection?.runtimeType == section.runtimeType &&
        _movingSection?.id == section.id;
    final focusNode = _getFocusNode(section);

    return FocusableSettingsTile(
      key: ValueKey((section.runtimeType, section.id)),
      focusNode: focusNode,
      autofocus: autofocus,
      selected: isMoving,
      leading: Icon(isMoving ? Icons.drag_indicator : Icons.drag_handle),
      title: Text(title),
      trailing: isMoving
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_up),
                Icon(Icons.keyboard_arrow_down),
              ],
            )
          : null,
      onLongPress: () => setState(() => _movingSection = section),
      onPressed: () {
        if (isMoving) {
          _endMove();
          return;
        }
        if (section is ContinueWatchingSection) {
          Navigator.pushNamed(context, ContinueWatchingSettingsPage.routeName);
        } else {
          _openEditor(
            index: _appsService.launcherSections.indexWhere(
              (s) => s.runtimeType == section.runtimeType && s.id == section.id,
            ),
          );
        }
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (isMoving) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveSection(section, -1, settingsService);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveSection(section, 1, settingsService);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _endMove();
            return KeyEventResult.handled;
          }
        } else {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final sections = _navigationSections(settingsService);
            final index = sections.indexWhere(
              (s) => s.runtimeType == section.runtimeType && s.id == section.id,
            );
            final next =
                index +
                (event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1);
            if (index >= 0 && next >= 0 && next < sections.length) {
              _getFocusNode(sections[next]).requestFocus();
            } else if (next == sections.length) {
              _addFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
          // Not Moving
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              _movingSection = section;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            if (section is ContinueWatchingSection) {
              Navigator.pushNamed(
                context,
                ContinueWatchingSettingsPage.routeName,
              );
            } else {
              final idx = _appsService.launcherSections.indexWhere(
                (s) =>
                    s.runtimeType == section.runtimeType && s.id == section.id,
              );
              _openEditor(index: idx);
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  Future<void> _resetSections(SettingsService? settings) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showLauncherDialog<bool>(
      context: context,
      builder: (context) => LauncherAlertDialog(
        title: Text(l.resetSections),
        content: Text(l.resetSectionsConfirmation),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            isCancel: true,
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            primary: true,
            danger: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.resetSections),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _resetBusy) return;
    setState(() {
      _resetBusy = true;
      _movingSection = null;
    });
    try {
      await _appsService.persistSectionsOrder();
      await _appsService.resetSections();
      await settings?.setContinueWatchingOrder(0);
      await settings?.setShowContinueWatching(false);
      if (mounted) _focusSection(_navigationSections(settings).first);
    } finally {
      if (mounted) setState(() => _resetBusy = false);
    }
  }

  List<LauncherSection> _navigationSections(SettingsService? settings) => [
    ..._getDisplaySections(_appsService.launcherSections, settings),
    ..._hiddenSections(settings),
  ];

  Future<void> _moveSection(
    LauncherSection movingSection,
    int direction,
    SettingsService? settingsService,
  ) async {
    if (_moveBusy || _resetBusy) return;
    final isVisible = movingSection is ContinueWatchingSection
        ? settingsService?.showContinueWatching == true
        : movingSection is! Category || movingSection.visible;
    final displaySections = isVisible
        ? _getDisplaySections(_appsService.launcherSections, settingsService)
        : _hiddenSections(settingsService);
    final now = DateTime.now();
    if (_lastMoveTime != null &&
        now.difference(_lastMoveTime!) < const Duration(milliseconds: 60)) {
      return;
    }
    _lastMoveTime = now;

    final currentIndex = displaySections.indexWhere(
      (s) =>
          s.runtimeType == movingSection.runtimeType &&
          s.id == movingSection.id,
    );
    if (currentIndex == -1) return;
    final newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= displaySections.length) {
      if ((isVisible && direction > 0) || (!isVisible && direction < 0)) {
        _moveBusy = true;
        try {
          if (movingSection is ContinueWatchingSection) {
            if (!isVisible) {
              await settingsService?.setContinueWatchingOrder(
                _getDisplaySections(
                  _appsService.launcherSections,
                  settingsService,
                ).length,
              );
            }
            if (isVisible) await settingsService?.setContinueWatchingOrder(0);
            await settingsService?.setShowContinueWatching(!isVisible);
          } else if (movingSection is Category) {
            await _appsService.setCategoryVisible(movingSection.id, !isVisible);
          }
          if (mounted) _focusSection(movingSection);
        } finally {
          _moveBusy = false;
        }
      }
      return;
    }

    final otherSection = displaySections[newIndex];
    if (movingSection is ContinueWatchingSection) {
      await settingsService?.setContinueWatchingOrder(newIndex);
    } else if (otherSection is ContinueWatchingSection) {
      settingsService?.setContinueWatchingOrder(currentIndex);
    } else {
      final appSections = _appsService.launcherSections;
      final oldAppIndex = appSections.indexWhere(
        (s) =>
            s.runtimeType == movingSection.runtimeType &&
            s.id == movingSection.id,
      );
      final newAppIndex = appSections.indexWhere(
        (s) =>
            s.runtimeType == otherSection.runtimeType &&
            s.id == otherSection.id,
      );
      if (oldAppIndex != -1 && newAppIndex != -1) {
        _appsService.moveSectionInMemory(oldAppIndex, newAppIndex);
      }
    }

    setState(() {
      _movingSection = movingSection;
    });

    _focusSection(movingSection);
  }

  Future<void> _openEditor({int? index}) async {
    if (_resetBusy) return;
    final created = await Navigator.pushNamed(
      context,
      LauncherSectionPanelPage.routeName,
      arguments: index,
    );
    if (mounted && created is LauncherSection) _focusSection(created);
  }

  void _focusSection(LauncherSection section) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _getFocusNode(section);
      node.requestFocus();
      if (node.context != null) {
        Scrollable.ensureVisible(
          node.context!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 100),
        );
      }
    });
  }

  void _endMove() {
    _appsService.persistSectionsOrder();
    setState(() {
      _movingSection = null;
    });
  }
}
