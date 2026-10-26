import 'settings/settings_page_layout.dart';
import 'settings/settings_menu_layout.dart';
import 'settings/focusable_settings_tile.dart';
import '../providers/settings_service.dart';

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
import 'package:flauncher/widgets/side_panel_dialog.dart';

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

class _ApplicationInfoPanelState extends State<ApplicationInfoPanel>
    with WidgetsBindingObserver {
  bool _running = false;
  bool _stopping = false;
  int _processRequest = 0;

  Future<void> _refreshProcess() async {
    final request = ++_processRequest;
    try {
      final result = await TvCleanerClient().call(
        'appProcessStatus',
        packages: [widget.application.packageName],
      );
      if (mounted && request == _processRequest) {
        setState(
          () => _running =
              result['status'] == 'success' && result['running'] == true,
        );
      }
    } catch (_) {
      if (mounted && request == _processRequest) {
        setState(() => _running = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_stopping) {
      _refreshProcess();
    }
  }

  Future<void> _stopApp() async {
    if (_stopping) return;
    ++_processRequest;
    setState(() => _stopping = true);
    try {
      final result = await TvCleanerClient().call(
        'stopApp',
        packages: [widget.application.packageName],
      );
      if (!mounted) return;
      showAdbNotice(context, result['status'] as String?);
    } catch (_) {
      if (mounted) showAdbNotice(context, 'unavailable');
    } finally {
      if (mounted) {
        setState(() => _stopping = false);
        await _refreshProcess();
        if (mounted && !_running) _appInfoNode.requestFocus();
      }
    }
  }

  late Future<bool> _hasCustomBannerFuture;
  late Future<Uint8List> _applicationIconFuture;
  final _addToCategoryNode = FocusNode();
  final _removeFromCategoryNode = FocusNode();
  final _appInfoNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshProcess();
    _hasCustomBannerFuture = context.read<AppsService>().hasCustomBanner(
      widget.application.packageName,
    );
    _applicationIconFuture = widget.applicationIcon == null
        ? context.read<AppsService>().getAppIcon(widget.application.packageName)
        : Future.value(Uint8List(0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addToCategoryNode.dispose();
    _removeFromCategoryNode.dispose();
    _appInfoNode.dispose();
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

  Widget _buildPanel(BuildContext context) {
    final localizations = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final page = SettingsPageLayout(
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
        ],
      ),
      child: ListView(
        children: [
          // Add to Category button (First as requested)
          FocusableSettingsTile(
            autofocus: true,
            focusNode: _addToCategoryNode,
            leading: const Icon(Icons.add_box_outlined),
            title: Text(
              AppLocalizations.of(context)!.addToCategory,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onPressed: () async {
              await showAddToCategoryDialog(
                context,
                widget.application,
                parentPanelWidth: widget.embedded
                    ? null
                    : LauncherStyle.of(context).settingsWidth,
              );
              if (mounted) _addToCategoryNode.requestFocus();
            },
          ),
          // Reorder button (Second as requested)
          if (widget.category?.sort == CategorySort.manual)
            FocusableSettingsTile(
              leading: const Icon(Icons.open_with),
              title: Text(
                localizations.reorder,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onPressed: () =>
                  Navigator.of(context)
                      .pop(ApplicationInfoPanelResult.reorderApp),
            ),
          if (widget.application.isLaunchable)
            FocusableSettingsTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(
                localizations.open,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onPressed: () async {
                await context.read<AppsService>().launchApp(widget.application);
                if (!context.mounted) return;
                Navigator.of(context).pop(ApplicationInfoPanelResult.none);
              },
            ),
          FocusableSettingsTile(
            leading: Icon(
              (widget.application.hidden || context.watch<AppsService>().isTileHidden(widget.application))
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
            ),
            title: Text(
              (widget.application.hidden || context.watch<AppsService>().isTileHidden(widget.application))
                  ? localizations.show
                  : localizations.hide,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onPressed: () async {
              if (widget.application.hidden || context.read<AppsService>().isTileHidden(widget.application)) {
                await context.read<AppsService>().showApplication(
                  widget.application,
                );
              } else {
                await context.read<AppsService>().hideApplication(
                  widget.application,
                );
              }
              if (!context.mounted) return;
              Navigator.of(context).pop(ApplicationInfoPanelResult.none);
            },
          ),
          if (widget.category != null && !widget.category!.isAutomatic)
            FocusableSettingsTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(
                localizations.removeFrom(
                  localizedSectionName(
                    widget.category?.name ?? '',
                    localizations,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                final cat = widget.category;
                if (cat != null) {
                  await context.read<AppsService>().removeFromCategory(
                    widget.application,
                    cat,
                  );
                }
                if (!context.mounted) return;
                Navigator.of(context).pop(ApplicationInfoPanelResult.none);
              },
            ),
          if (widget.category == null || widget.category!.isAutomatic)
            FocusableSettingsTile(
              focusNode: _removeFromCategoryNode,
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(localizations.removeFromCategory),
              onPressed: () async {
                await showRemoveFromCategoryDialog(
                  context,
                  widget.application,
                  parentPanelWidth: widget.embedded
                      ? null
                      : LauncherStyle.of(context).settingsWidth,
                );
                if (mounted) _removeFromCategoryNode.requestFocus();
              },
            ),
          const Divider(),
          FutureBuilder<bool>(
            future: _hasCustomBannerFuture,
            builder: (context, snapshot) {
              final hasCustom = snapshot.data ?? false;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FocusableSettingsTile(
                    leading: const Icon(Icons.image_search),
                    title: Text(
                      AppLocalizations.of(context)!.setCustomBanner,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onPressed: () async {
                      try {
                        final pickedFile = await DocumentFiles.pickImage();
                        if (pickedFile != null) {
                          final imageBytes = await DocumentFiles.readImage(
                            pickedFile,
                          );
                          if (!mounted) return;
                          final docDir =
                              await getApplicationDocumentsDirectory();
                          // Sanitize package name for filename
                          final safePackageName = widget.application.packageName
                              .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
                          final savedImage = File(
                            '${docDir.path}/custom_banner_$safePackageName.png',
                          );
                          await savedImage.writeAsBytes(
                            imageBytes,
                            flush: true,
                          );
                          if (!context.mounted) return;
                          await context.read<AppsService>().setCustomAppBanner(
                            widget.application.packageName,
                            savedImage.path,
                          );
                          // Refresh the future to reflect the change
                          setState(() {
                            _hasCustomBannerFuture = context
                                .read<AppsService>()
                                .hasCustomBanner(
                                  widget.application.packageName,
                                );
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showActionNotice(
                            context,
                            AppLocalizations.of(context)!.bannerSetFailed,
                            error: true,
                          );
                        }
                      }
                      if (context.mounted) {
                        Navigator.of(context)
                            .pop(ApplicationInfoPanelResult.none);
                      }
                    },
                  ),
                  if (hasCustom)
                    FocusableSettingsTile(
                      leading: const Icon(Icons.hide_image_outlined),
                      title: Text(
                        AppLocalizations.of(context)!.clearCustomBanner,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onPressed: () async {
                        try {
                          await context
                              .read<AppsService>()
                              .removeCustomAppBanner(
                                widget.application.packageName,
                              );
                          // Refresh the future to reflect the change
                          setState(() {
                            _hasCustomBannerFuture = context
                                .read<AppsService>()
                                .hasCustomBanner(
                                  widget.application.packageName,
                                );
                          });
                        } catch (e) {
                          if (context.mounted) {
                            showActionNotice(
                              context,
                              AppLocalizations.of(context)!.bannerClearFailed,
                              error: true,
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.of(context)
                              .pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                ],
              );
            },
          ),
          const Divider(),
          if (_running)
            FocusableSettingsTile(
              leading: _stopping
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.stop_circle_outlined),
              title: Text(
                localizations.stopApp,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onPressed: _stopApp,
            ),
          FocusableSettingsTile(
            focusNode: _appInfoNode,
            leading: const Icon(Icons.info_outlined),
            title: Text(
              localizations.appInfo,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onPressed: () =>
                context.read<AppsService>().openAppInfo(widget.application),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.delete_outlined),
            title: Text(
              localizations.uninstall,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onPressed: () async {
              await context.read<AppsService>().uninstallApp(
                widget.application,
              );
              if (!context.mounted) return;
              Navigator.of(context).pop(ApplicationInfoPanelResult.none);
            },
          ),
        ],
      ),
    );
    if (widget.embedded) return page;
    return SidePanelDialog(
      width: LauncherStyle.of(context).settingsWidth,
      child: page,
    );
  }
}

enum ApplicationInfoPanelResult { none, reorderApp }
