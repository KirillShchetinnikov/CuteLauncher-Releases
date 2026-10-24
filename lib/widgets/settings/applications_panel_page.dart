import '../../theme/interface_style.dart';
import 'focusable_settings_tile.dart';
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

import 'package:flauncher/providers/apps_service.dart';

import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/app_details_page.dart';
import 'package:flutter/services.dart';

import '../../models/app.dart';

class ApplicationsPanelPage extends StatefulWidget {
  static const String routeName = "applications_panel";

  const ApplicationsPanelPage({super.key});

  @override
  State<ApplicationsPanelPage> createState() => _ApplicationsPanelPageState();
}

class _ApplicationsPanelPageState extends State<ApplicationsPanelPage> {
  int _selectedIndex = 0;
  bool _isSwitchingViaKeyboard = false;

  final List<_TabData> _tabs = [
    _TabData(0, Icons.apps, (l) => l.allApplications),
    _TabData(1, Icons.android, (l) => l.systemApplications),
    _TabData(2, Icons.visibility_off_outlined, (l) => l.hiddenApplications),
  ];

  late List<FocusNode> _tabFocusNodes;

  @override
  void initState() {
    super.initState();
    _tabFocusNodes = List.generate(_tabs.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var node in _tabFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return SettingsPageLayout(
      title: Text(
        _tabs[_selectedIndex].getTitle(localizations),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _tabs
                  .map(
                    (tab) => _buildTabButton(
                      tab.index,
                      tab.icon,
                      tab.getTitle(localizations),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const ChangeTabIntent(
            -1,
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const ChangeTabIntent(
            1,
          ),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ChangeTabIntent: _ChangeTabAction(this),
            MoveFocusToTabIntent: _MoveFocusToTabAction(this),
          },
          child: _buildCurrentTab(),
        ),
      ),
    );
  }

  void _selectTab(int index, String title) {
    if (_selectedIndex != index) {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  void changeTab(int direction) {
    // ... (existing code, ensure it matches previous edits)

    final newIndex = (_selectedIndex + direction).clamp(0, _tabs.length - 1);
    if (newIndex != _selectedIndex) {
      final localizations = AppLocalizations.of(context)!;

      _isSwitchingViaKeyboard = true;
      _selectTab(newIndex, _tabs[newIndex].getTitle(localizations));

      _tabFocusNodes[newIndex].requestFocus();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _isSwitchingViaKeyboard = false;
        }
      });
    }
  }

  void focusCurrentTab() {
    _tabFocusNodes[_selectedIndex].requestFocus();
  }

  Widget _buildTabButton(int index, IconData icon, String title) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Focus(
          focusNode: _tabFocusNodes[index],
          onFocusChange: (focused) {
            if (focused) {
              if (_isSwitchingViaKeyboard) {
                return;
              }

              _selectTab(index, title);
            }
          },
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              final selected = _selectedIndex == index;
              return navButton(selected, focused, index, title, icon);
            },
          ),
        ),
      ),
    );
  }

  Widget navButton(
    bool selected,
    bool focused,
    int index,
    String title,
    IconData icon,
  ) {
    // ... (same)
    return InkWell(
      canRequestFocus: false,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        _selectTab(index, title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: InterfaceSkin.of(context).surface(
          selected
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .15)
              : Colors.transparent,
          Theme.of(context).colorScheme.onSurface,
          focused: focused,
          accent: Theme.of(context).colorScheme.primary,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildCurrentTab() {
    // ... (same)
    switch (_selectedIndex) {
      case 0:
        return _AllTab();
      case 1:
        return _SystemTab();
      case 2:
        return _HiddenTab();
      default:
        return Container();
    }
  }
}

class _TabData {
  final int index;
  final IconData icon;
  final String Function(AppLocalizations) getTitle;

  _TabData(this.index, this.icon, this.getTitle);
}

class MoveFocusToTabIntent extends Intent {
  const MoveFocusToTabIntent();
}

class _MoveFocusToTabAction extends Action<MoveFocusToTabIntent> {
  final _ApplicationsPanelPageState state;
  _MoveFocusToTabAction(this.state);
  @override
  Object? invoke(MoveFocusToTabIntent intent) {
    state.focusCurrentTab();
    return null;
  }
}

class ChangeTabIntent extends Intent {
  final int direction;
  const ChangeTabIntent(this.direction);
}

class _ChangeTabAction extends Action<ChangeTabIntent> {
  final _ApplicationsPanelPageState state;

  _ChangeTabAction(this.state);

  @override
  Object? invoke(ChangeTabIntent intent) {
    state.changeTab(intent.direction);
    return null;
  }
}

class _AllTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) => [
      for (final category in appsService.categories)
        if (category.systemKey == 'all_apps') ...category.applications,
    ],
    builder: (context, applications, _) {
      if (applications.isEmpty) {
        return _EmptyListPlaceholder(
          AppLocalizations.of(context)!.noApplicationsFound,
          autofocus: true,
        );
      }
      return ListView(
        children: applications
            .asMap()
            .entries
            .map(
              (entry) => EnsureVisible(
                key: ValueKey(entry.value.packageName),
                alignment: 0.5,
                child: _AppListItem(
                  entry.value,
                  autofocus: entry.key == 0,
                  isFirst: entry.key == 0,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _SystemTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) => appsService.applications
        .where((app) => app.isSystem && !app.hidden && !appsService.isTileHidden(app))
        .toList(),
    builder: (context, applications, _) {
      if (applications.isEmpty) {
        return _EmptyListPlaceholder(
          AppLocalizations.of(context)!.noApplicationsFound,
          autofocus: true,
        );
      }
      return ListView(
        children: applications
            .asMap()
            .entries
            .map(
              (entry) => EnsureVisible(
                key: ValueKey(entry.value.packageName),
                alignment: 0.5,
                child: _AppListItem(
                  entry.value,
                  autofocus: entry.key == 0,
                  isFirst: entry.key == 0,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _HiddenTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) =>
        appsService.applications.where((app) => app.hidden || appsService.isTileHidden(app)).toList(),
    builder: (context, applications, _) {
      if (applications.isEmpty) {
        return _EmptyListPlaceholder(
          AppLocalizations.of(context)!.noApplicationsFound,
          autofocus: true,
        );
      }
      return ListView(
        children: applications
            .asMap()
            .entries
            .map(
              (entry) => EnsureVisible(
                key: ValueKey(entry.value.packageName),
                alignment: 0.5,
                child: _AppListItem(
                  entry.value,
                  autofocus: entry.key == 0,
                  isFirst: entry.key == 0,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _EmptyListPlaceholder extends StatefulWidget {
  final String message;
  final bool autofocus;

  const _EmptyListPlaceholder(this.message, {this.autofocus = false});

  @override
  State<_EmptyListPlaceholder> createState() => _EmptyListPlaceholderState();
}

class _EmptyListPlaceholderState extends State<_EmptyListPlaceholder> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveFocusToTabIntent(),
      },
      child: Focus(
        focusNode: _focusNode,
        child: Center(
          child: Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _AppListItem extends StatefulWidget {
  final App application;
  final bool autofocus;
  final bool isFirst;

  const _AppListItem(
    this.application, {
    this.autofocus = false,
    this.isFirst = false,
  });

  @override
  State<StatefulWidget> createState() => _AppListItemState();
}

class _AppListItemState extends State<_AppListItem> {
  late Future<ImageProvider> _iconLoadFuture;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _iconLoadFuture = _loadAppIcon(
      Provider.of<AppsService>(context, listen: false),
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AppListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application.packageName != widget.application.packageName) {
      _iconLoadFuture = _loadAppIcon(
        Provider.of<AppsService>(context, listen: false),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openAppDetails() {
    Navigator.of(context)
        .pushNamed(AppDetailsPage.routeName, arguments: widget.application);
  }

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    focusNode: _focusNode,
    onKeyEvent: (node, event) {
      if (widget.isFirst &&
          event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        Actions.invoke(context, const MoveFocusToTabIntent());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    title: Text(widget.application.name),
    leading: FutureBuilder<ImageProvider>(
      future: _iconLoadFuture,
      builder: (context, snapshot) => snapshot.hasData
          ? Image(image: snapshot.data!, height: 40)
          : Icon(snapshot.hasError ? Icons.warning : Icons.android),
    ),
    onPressed: _openAppDetails,
  );
  Future<ImageProvider> _loadAppIcon(AppsService service) async {
    Uint8List bytes = await service.getAppIcon(widget.application.packageName);
    return MemoryImage(bytes);
  }
}
