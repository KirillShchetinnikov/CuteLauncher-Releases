import '../application_info_configuration.dart';
import 'menu_header_action.dart';
import 'settings/application_info_settings_page.dart';
import 'settings/settings_route.dart';
import 'settings/settings_section.dart';
import 'settings/settings_page_layout.dart';
import 'settings/settings_menu_layout.dart';
import 'settings/focusable_settings_tile.dart';
import '../providers/settings_service.dart';
import 'background_startup_app_tile.dart';

import 'package:flauncher/widgets/action_notice.dart';
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

import 'dart:io';
import 'dart:typed_data';

import '../document_files.dart';
import '../tv_cleaner.dart';
import 'settings/adb_notice.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';

import 'app_name_dialog.dart';
import 'settings/settings_panel_style.dart';

import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/l10n/app_localizations_en.dart';

import '../models/app.dart';
import '../theme/launcher_style.dart';

import 'package:flauncher/section_names.dart';

import '../models/category.dart';

class ApplicationInfoPanel extends StatefulWidget {
  final bool embedded;
  final Category? category;
  final App application;
  final ImageProvider? applicationIcon;

  const ApplicationInfoPanel({
    super.key,
    this.embedded = false,
    required this.category,
    required this.application,
    this.applicationIcon,
  });

  @override
  State<ApplicationInfoPanel> createState() => _ApplicationInfoPanelState();
}

enum _ProcessAction { stop, restart }

class _ApplicationInfoPanelState extends State<ApplicationInfoPanel> {
  bool? _running;
  bool _checking = false;
  String? _processError;
  _ProcessAction? _processAction;
  bool _sectionsExpanded = false;
  bool _editingName = false;
  bool _editingSettings = false;
  int _processRequest = 0;

  Future<void> _editAppName(BuildContext context) async {
    if (_editingName) return;
    _editingName = true;
    final apps = context.read<AppsService>();
    try {
      final packageName = widget.application.packageName;
      final application = apps.getApp(packageName) ?? widget.application;
      final initialName = application.displayName;
      final result = await showLauncherDialog<String>(
        context: context,
        builder: (_) => AppNameDialog(
          initialName: initialName,
          canRestoreSystemName: application.customName != null,
        ),
      );
      if (result == null || result == initialName || !context.mounted) return;
      await apps.setCustomAppName(packageName, result.isEmpty ? null : result);
    } catch (_) {
      if (context.mounted) {
        showActionNotice(
          context,
          (AppLocalizations.of(context) ?? AppLocalizationsEn()).appError,
          error: true,
        );
      }
    } finally {
      _editingName = false;
    }
  }

  Future<void> _refreshProcess() async {
    if (_checking || _processAction != null) return;
    final request = ++_processRequest;
    setState(() {
      _checking = true;
      _processError = null;
    });
    try {
      final result = await TvCleanerClient().call(
        'appProcessStatus',
        packages: [widget.application.packageName],
      );
      if (mounted && request == _processRequest) {
        setState(() => _setProcessResult(result));
      }
    } catch (_) {
      if (mounted && request == _processRequest) {
        setState(() {
          _running = null;
          _processError = 'unavailable';
        });
      }
    } finally {
      if (mounted && request == _processRequest) {
        setState(() => _checking = false);
      }
    }
  }

  void _setProcessResult(Map<String, dynamic> result) {
    final status = result['status'];
    final known =
        (status == 'success' || status == 'denied') &&
        result['running'] is bool;
    _running = known ? result['running'] as bool : null;
    _processError = known ? null : status as String? ?? 'unavailable';
  }

  Future<void> _stopOrRestart(_ProcessAction action) async {
    final application = widget.application;
    final restart = action == _ProcessAction.restart;
    if (_processAction != null ||
        _checking ||
        _running != true ||
        (restart && !application.isLaunchable)) {
      return;
    }
    final route = ModalRoute.of(context);
    ++_processRequest;
    setState(() => _processAction = action);
    try {
      final result = await TvCleanerClient().call(
        'stopApp',
        packages: [application.packageName],
      );
      if (!mounted) return;
      final status = result['status'] as String?;
      final stopped = status == 'success' && result['running'] == false;
      if (restart && stopped) {
        if (route?.isCurrent != false &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          await _launchAfterStop(application, route);
          if (!mounted) return;
        }
      } else if (route?.isCurrent != false) {
        showAdbNotice(
          context,
          restart && status == 'success' ? 'operation_failed' : status,
        );
      }
      setState(() => _setProcessResult(result));
    } catch (_) {
      if (mounted) {
        setState(() {
          _running = null;
          _processError = 'unavailable';
        });
        if (route?.isCurrent != false) showAdbNotice(context, 'unavailable');
      }
    } finally {
      if (mounted) {
        setState(() => _processAction = null);
        if (_running != true && route?.isCurrent != false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || route?.isCurrent == false) return;
            final info = _actionNodes[ApplicationInfoAction.androidInfo]!;
            final target = info.context != null && info.canRequestFocus
                ? info
                : _actionNodes.values.firstWhere(
                    (node) => node.context != null && node.canRequestFocus,
                    orElse: () => _settingsNode,
                  );
            target.requestFocus();
          });
        }
      }
    }
  }

  Future<void> _launchAfterStop(
    App application,
    ModalRoute<dynamic>? route,
  ) async {
    var launched = false;
    try {
      launched = await context.read<AppsService>().launchApp(application);
    } catch (_) {
      // The stop was already verified, so preserve that result.
    }
    if (!mounted || route?.isCurrent == false) return;
    if (launched) {
      Navigator.of(context).pop(ApplicationInfoPanelResult.none);
    } else {
      final l = AppLocalizations.of(context) ?? AppLocalizationsEn();
      showActionNotice(context, l.appRestartLaunchFailed, error: true);
    }
  }

  late Future<bool> _hasCustomBannerFuture;
  late Future<Uint8List> _applicationIconFuture;
  final _actionNodes = {
    for (final action in ApplicationInfoAction.values) action: FocusNode(),
  };
  final _settingsNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hasCustomBannerFuture = context.read<AppsService>().hasCustomBanner(
      widget.application.packageName,
    );
    _applicationIconFuture = widget.applicationIcon == null
        ? context.read<AppsService>().getAppIcon(widget.application.packageName)
        : Future.value(Uint8List(0));
    final configuration = ApplicationInfoConfiguration.decode(
      context.read<SettingsService?>()?.storedApplicationInfoConfiguration,
    );
    if (configuration.checkOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) {
          _refreshProcess();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final node in _actionNodes.values) {
      node.dispose();
    }
    _settingsNode.dispose();
    super.dispose();
  }

  Widget _appIcon(BuildContext context) {
    const fallback = Icon(Icons.apps_rounded, size: 40);
    return SizedBox(
      width: 50,
      height: 50,
      child: widget.applicationIcon != null
          ? Image(
              image: widget.applicationIcon!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => fallback,
            )
          : FutureBuilder<Uint8List>(
              future: _applicationIconFuture,
              builder: (context, snapshot) =>
                  snapshot.hasData && snapshot.data!.isNotEmpty
                  ? Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      cacheWidth: (50 * MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1, 256),
                      errorBuilder: (_, _, _) => fallback,
                    )
                  : fallback,
            ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _buildPanel(context)
      : SettingsPanelStyle(
          builder: (context) => SettingsMenuLayout(
            onRight:
                context.watch<SettingsService?>()?.settingsMenuOnRight ?? false,
            child: Builder(builder: _buildPanel),
          ),
        );

  Future<void> _openSettings(BuildContext context) async {
    if (_editingSettings) return;
    _editingSettings = true;
    try {
      if (widget.embedded) {
        await Navigator.of(context).push(
          SettingsRoute<void>(
            builder: (_) => const ApplicationInfoSettingsPage(),
          ),
        );
      } else {
        await showLauncherDialog<void>(
          context: context,
          parentPanelWidth: LauncherStyle.of(context).settingsWidth,
          builder: (_) => SettingsPanelStyle(
            builder: (context) => SettingsMenuLayout(
              onRight:
                  context.watch<SettingsService?>()?.settingsMenuOnRight ??
                  false,
              child: SidePanelDialog(
                width: LauncherStyle.of(context).settingsWidth,
                child: const ApplicationInfoSettingsPage(),
              ),
            ),
          ),
        );
      }
      if (mounted) _settingsNode.requestFocus();
    } finally {
      _editingSettings = false;
    }
  }

  Future<void> _setBanner(BuildContext context) async {
    try {
      final pickedFile = await DocumentFiles.pickImage(
        context: context,
        selectionKey: 'banner:${widget.application.packageName}',
      );
      if (pickedFile != null) {
        final imageBytes = await DocumentFiles.readImage(pickedFile);
        if (!mounted) return;
        final docDir = await getApplicationDocumentsDirectory();
        final safePackageName = widget.application.packageName.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final savedImage = File(
          '${docDir.path}/custom_banner_$safePackageName.png',
        );
        await savedImage.writeAsBytes(imageBytes, flush: true);
        if (!context.mounted) return;
        await context.read<AppsService>().setCustomAppBanner(
          widget.application.packageName,
          savedImage.path,
        );
        if (!context.mounted) return;
        await DocumentFiles.rememberImageSelection(
          pickedFile,
          context.read<SettingsService>(),
        );
      }
    } catch (_) {
      if (context.mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.bannerSetFailed,
          error: true,
        );
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop(ApplicationInfoPanelResult.none);
    }
  }

  Future<void> _clearBanner(BuildContext context) async {
    try {
      await context.read<AppsService>().removeCustomAppBanner(
        widget.application.packageName,
      );
    } catch (_) {
      if (context.mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.bannerClearFailed,
          error: true,
        );
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop(ApplicationInfoPanelResult.none);
    }
  }

  Future<void> _addToSection(BuildContext context) async {
    await showAddToCategoryDialog(
      context,
      widget.application,
      parentPanelWidth: widget.embedded
          ? null
          : LauncherStyle.of(context).settingsWidth,
    );
    if (mounted) {
      _actionNodes[ApplicationInfoAction.addToSection]!.requestFocus();
    }
  }

  Future<void> _removeFromSection(
    BuildContext context,
    Category? section,
  ) async {
    if (section != null && !section.isAutomatic) {
      await context.read<AppsService>().removeFromCategory(
        widget.application,
        section,
      );
      if (context.mounted) {
        Navigator.of(context).pop(ApplicationInfoPanelResult.none);
      }
      return;
    }
    await showRemoveFromCategoryDialog(
      context,
      widget.application,
      parentPanelWidth: widget.embedded
          ? null
          : LauncherStyle.of(context).settingsWidth,
    );
    if (mounted) {
      _actionNodes[ApplicationInfoAction.removeFromSection]!.requestFocus();
    }
  }

  Widget _buildPanel(BuildContext context) => FutureBuilder<bool>(
    future: _hasCustomBannerFuture,
    builder: (context, snapshot) =>
        _buildContent(context, snapshot.data == true),
  );

  Widget _buildContent(BuildContext context, bool hasCustomBanner) {
    final l = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final apps = context.watch<AppsService>();
    final configuration = ApplicationInfoConfiguration.decode(
      context.select<SettingsService?, String?>(
        (settings) => settings?.storedApplicationInfoConfiguration,
      ),
    );
    final actions = <ApplicationInfoAction, Widget>{};
    for (final action in configuration.order) {
      if (configuration.hidden.contains(action)) continue;
      final control = _buildAction(context, l, apps, action, hasCustomBanner);
      if (control != null) {
        actions[action] = KeyedSubtree(key: ValueKey(action), child: control);
      }
    }
    // Background startup has a separate availability check. Skip it until actionable.
    final initialFocus = actions.keys
        .where((action) {
          final node = _actionNodes[action]!;
          return action != ApplicationInfoAction.backgroundStartup ||
              node.context != null && node.canRequestFocus;
        })
        .map((action) => _actionNodes[action]!)
        .firstOrNull;
    final showStandaloneStatus =
        configuration.checkOnOpen &&
        !actions.containsKey(ApplicationInfoAction.checkProcess);
    final page = SettingsPageLayout(
      initialFocus: initialFocus ?? _settingsNode,
      title: Row(
        children: [
          _appIcon(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.application.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.application.packageName,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'v${widget.application.version}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (context.read<SettingsService?>() != null)
            MenuHeaderAction(
              key: const ValueKey('application_info_settings'),
              focusNode: _settingsNode,
              tooltip: l.applicationInfoSettings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _openSettings(context),
            ),
        ],
      ),
      child: ListView(
        children: [
          if (showStandaloneStatus) _statusText(l),
          if (actions.isEmpty && !showStandaloneStatus)
            Text(l.applicationInfoNoActions),
          if (configuration.usesDefaultOrder)
            ..._groupedActions(l, actions)
          else
            ...actions.values,
        ],
      ),
    );
    if (widget.embedded) return page;
    return SidePanelDialog(
      width: LauncherStyle.of(context).settingsWidth,
      child: page,
    );
  }

  List<Widget> _groupedActions(
    AppLocalizations l,
    Map<ApplicationInfoAction, Widget> actions,
  ) {
    final titles = {
      ApplicationInfoGroup.home: l.homeScreen,
      ApplicationInfoGroup.launch: l.appLaunchGroup,
      ApplicationInfoGroup.appearance: l.appearanceSettings,
      ApplicationInfoGroup.management: l.appManagementGroup,
    };
    final groups = <ApplicationInfoGroup, List<Widget>>{};
    for (final entry in actions.entries) {
      (groups[entry.key.group] ??= []).add(entry.value);
    }
    return [
      for (final group in groups.entries)
        SettingsSection(
          key: ValueKey(group.key),
          title: titles[group.key]!,
          children: group.value,
        ),
    ];
  }

  Widget? _buildAction(
    BuildContext context,
    AppLocalizations l,
    AppsService apps,
    ApplicationInfoAction action,
    bool hasCustomBanner,
  ) {
    final app = widget.application;
    final category = widget.category;
    final focusNode = _actionNodes[action]!;
    Widget tile(
      VoidCallback onPressed, {
      String? label,
      Widget? leading,
      bool busy = false,
      Key? key,
    }) => FocusableSettingsTile(
      key: key,
      focusNode: focusNode,
      title: Text(
        label ?? action.label(l),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      leading: leading ?? Icon(action.icon),
      busy: busy,
      onPressed: onPressed,
    );

    switch (action) {
      case ApplicationInfoAction.addToSection:
        return tile(() => _addToSection(context));
      case ApplicationInfoAction.reorderTile:
        if (category?.sort != CategorySort.manual) return null;
        return tile(
          () =>
              Navigator.of(context).pop(ApplicationInfoPanelResult.reorderApp),
        );
      case ApplicationInfoAction.visibility:
        final hidden = app.hidden || apps.isTileHidden(app);
        return tile(
          () async {
            if (app.hidden || apps.isTileHidden(app)) {
              await apps.showApplication(app);
            } else {
              await apps.hideApplication(app);
            }
            if (context.mounted) {
              Navigator.of(context).pop(ApplicationInfoPanelResult.none);
            }
          },
          label: hidden ? l.show : l.hide,
          leading: Icon(
            hidden ? Icons.visibility : Icons.visibility_off_outlined,
          ),
        );
      case ApplicationInfoAction.removeFromSection:
        return tile(
          () => _removeFromSection(context, category),
          label: category != null && !category.isAutomatic
              ? l.removeFrom(localizedSectionName(category.name, l))
              : null,
        );
      case ApplicationInfoAction.sections:
        return _appSections(l, apps, focusNode);
      case ApplicationInfoAction.open:
        if (!app.isLaunchable) return null;
        return tile(() async {
          await apps.launchApp(app);
          if (context.mounted) {
            Navigator.of(context).pop(ApplicationInfoPanelResult.none);
          }
        }, busy: _processAction != null);
      case ApplicationInfoAction.backgroundStartup:
        return BackgroundStartupAppTile(
          packageName: app.packageName,
          focusNode: focusNode,
        );
      case ApplicationInfoAction.rename:
        if (category == null) return null;
        return tile(() => _editAppName(context));
      case ApplicationInfoAction.setBanner:
        return tile(() => _setBanner(context));
      case ApplicationInfoAction.clearBanner:
        return hasCustomBanner ? tile(() => _clearBanner(context)) : null;
      case ApplicationInfoAction.checkProcess:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tile(
              _refreshProcess,
              key: const ValueKey('app_check_process'),
              busy: _checking || _processAction != null,
            ),
            _statusText(l),
          ],
        );
      case ApplicationInfoAction.stop:
      case ApplicationInfoAction.restart:
        final restart = action == ApplicationInfoAction.restart;
        if (_running != true || restart && !app.isLaunchable) return null;
        final processAction = restart
            ? _ProcessAction.restart
            : _ProcessAction.stop;
        return tile(
          () => _stopOrRestart(processAction),
          busy: _checking || _processAction != null,
          leading: _processAction == processAction
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        );
      case ApplicationInfoAction.androidInfo:
        return tile(() => apps.openAppInfo(app));
      case ApplicationInfoAction.uninstall:
        return tile(() async {
          await apps.uninstallApp(app);
          if (context.mounted) {
            Navigator.of(context).pop(ApplicationInfoPanelResult.none);
          }
        });
    }
  }

  Widget _statusText(AppLocalizations l) {
    final status = _checking
        ? l.loading
        : _processError != null
        ? switch (_processError) {
            'authorization' => l.adbAuthorization,
            'unavailable' => l.adbUnavailable,
            _ => l.appError,
          }
        : switch (_running) {
            true => l.appProcessRunning,
            false => l.appProcessStopped,
            null => l.appProcessNotChecked,
          };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
      child: Semantics(liveRegion: true, child: Text(status)),
    );
  }

  Widget _appSections(
    AppLocalizations l,
    AppsService apps,
    FocusNode focusNode,
  ) {
    final app = widget.application;
    final sections =
        apps.categories
            .where(
              (section) =>
                  !section.isAppChannels &&
                  ((!section.isAutomatic &&
                          app.categoryOrders.containsKey(section.id)) ||
                      section.applications.any(
                        (entry) => entry.packageName == app.packageName,
                      )),
            )
            .toList()
          ..sort((a, b) {
            final order = a.order.compareTo(b.order);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _sectionsExpanded,
          child: FocusableSettingsTile(
            focusNode: focusNode,
            leading: Icon(ApplicationInfoAction.sections.icon),
            title: Text(l.appSections),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${sections.length}'),
                const SizedBox(width: 8),
                Icon(_sectionsExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onPressed: () =>
                setState(() => _sectionsExpanded = !_sectionsExpanded),
          ),
        ),
        if (_sectionsExpanded)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sections.isEmpty) Text(l.noAppSections),
                for (final section in sections)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(localizedSectionName(section.name, l)),
                        ),
                        if (!section.visible)
                          Icon(
                            Icons.visibility_off_outlined,
                            semanticLabel: l.hiddenCategories,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

enum ApplicationInfoPanelResult { none, reorderApp }
