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

import 'service_lifecycle.dart';
import 'memory_resources.dart';
import '../image_byte_cache.dart';
import '../image_limits.dart';
import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:collection/collection.dart' as collection;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';

import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart';
import 'package:pool/pool.dart';

import '../models/app.dart';
import '../models/category.dart';

class AppsService extends ChangeNotifier with ServiceLifecycle {
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _database;
  final SettingsService? _settingsService;
  final String? _ownPackageName;
  final MemoryResources? _memoryResources;
  int _imageGeneration = 0;

  bool _initialized = false;
  StreamSubscription<dynamic>? _appsSubscription;

  final List<LauncherSection> _launcherSections = List.empty(growable: true);
  Map<String, App> _applications = {};
  final _iconCache = ImageByteCache(maximumBytes: 2 * 1024 * 1024);
  final _bannerCache = ImageByteCache(maximumBytes: 6 * 1024 * 1024);
  final _imageLoads = <String, Future<Uint8List>>{};
  final _imagePool = Pool(2);
  int get imageCacheBytes => _iconCache.byteCount + _bannerCache.byteCount;
  int get imageCacheEntries => _iconCache.length + _bannerCache.length;

  void clearImageCaches() {
    ++_imageGeneration;
    _iconCache.clear();
    _bannerCache.clear();
    _imageLoads.clear();
  }

  void configureImageCache({required int iconBytes, required int bannerBytes}) {
    _iconCache.maximumBytes = iconBytes;
    _bannerCache.maximumBytes = bannerBytes;
  }

  Future<Uint8List> _loadImage(String key, Future<Uint8List> Function() loader) {
    if (isDisposed || _memoryResources?.isForeground == false) return Future.value(Uint8List(0));
    final generation = _imageGeneration;
    final scopedKey = '$_imageGeneration:$key';
    return _imageLoads.putIfAbsent(scopedKey, () async {
      try {
        return await _imagePool.withResource(() => isDisposed || generation != _imageGeneration || _memoryResources?.isForeground == false
            ? Future.value(Uint8List(0)) : loader());
      } finally { _imageLoads.remove(scopedKey); }
    });
  }

  Map<int, Category> _categoriesById = {};
  // Cached SharedPreferences instance to avoid repeated disk I/O
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _prefsAsync async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  bool get initialized => _initialized;

  String? _pendingReorderFocusPackage;
  int? _pendingReorderFocusCategoryId;
  int? _pendingReorderFocusIndex;
  String? get pendingReorderFocusPackage => _pendingReorderFocusPackage;
  int? get pendingReorderFocusCategoryId => _pendingReorderFocusCategoryId;
  int? get pendingReorderFocusIndex => _pendingReorderFocusIndex;
  void clearPendingReorderFocusPackage() {
    _pendingReorderFocusPackage = null;
    _pendingReorderFocusCategoryId = null;
    _pendingReorderFocusIndex = null;
  }

  void setPendingReorderFocus(String packageName, int categoryId, int index) {
    _pendingReorderFocusPackage = packageName;
    _pendingReorderFocusCategoryId = categoryId;
    _pendingReorderFocusIndex = index;
  }

  List<App> get applications => UnmodifiableListView(
      _applications.values.sortedBy((application) => application.name));

  List<LauncherSection> get launcherSections =>
      List.unmodifiable(_launcherSections.map((section) => section is Category ? _displayCategory(section) : section));
  List<LauncherSection> get visibleLauncherSections => launcherSections.where((section) => section is! Category || section.visible).toList(growable: false);
  List<Category> get categories => _categoriesById.values
      .map(_displayCategory)
      .toList(growable: false);

  bool _showTile(App app) =>
      (_settingsService?.hideLauncherTile != true || app.packageName != _ownPackageName) &&
      (_settingsService?.hideAndroidSettingsTile == false ||
          (app.packageName != 'com.android.tv.settings' &&
              app.packageName != 'com.android.settings' &&
              app.action != 'android.settings.SETTINGS'));

  /// Tile preferences hide apps independently of their stored manual flag.
  bool isTileHidden(App app) => !_showTile(app);

  Category _displayCategory(Category category) {
    if (category.isAutomatic) {
      final apps = _applications.values.where((app) => !app.hidden && app.isLaunchable && _showTile(app) &&
          switch (category.systemKey) {
            'all_apps' => true,
            'tv_apps' => !app.sideloaded,
            'other_apps' => app.sideloaded,
            _ => false,
          }).toList();
      final existing = category.applications.map((app) => app.packageName).toSet();
      if (existing.length != apps.length || apps.any((app) => !existing.contains(app.packageName))) {
        category.applications..clear()..addAll(apps);
        sortCategory(category);
      } else {
        for (var index = 0; index < category.applications.length; index++) {
          category.applications[index] = _applications[category.applications[index].packageName]!;
        }
        if (category.sort != CategorySort.manual) sortCategory(category);
      }
      return category.unmodifiable();
    }
    if (category.applications.every(_showTile)) return category.unmodifiable();
    return Category.withApplications(
      id: category.id, name: category.name, order: category.order, sort: category.sort,
      systemKey: category.systemKey, visible: category.visible,
      type: category.type, rowHeight: category.rowHeight, columnsCount: category.columnsCount,
      applications: List.unmodifiable(category.applications.where(_showTile)),
    );
  }

  AppsService(this._fLauncherChannel, this._database, {this._settingsService, this._ownPackageName, this._memoryResources}) {
    _memoryResources?.register(this, clear: clearImageCaches,
      activity: () => {
        for (final key in ['hits', 'misses', 'writes'])
          key: _iconCache.activity[key]! + _bannerCache.activity[key]!,
        'pending_loads': _imageLoads.length,
      },
      stats: () => MemoryCacheStats(imageCacheBytes, imageCacheEntries), resume: notifyListeners,
      breakdown: () => {
        MemoryCacheKind.appIcons: MemoryCacheStats(_iconCache.byteCount, _iconCache.length),
        MemoryCacheKind.appBanners: MemoryCacheStats(_bannerCache.byteCount, _bannerCache.length),
      },
      configure: (economy) => configureImageCache(iconBytes: (economy ? 1 : 2) * 1024 * 1024,
        bannerBytes: (economy ? 2 : 6) * 1024 * 1024));
    _settingsService?.addListener(notifyListeners);
    _init().catchError((Object error) {
      debugPrint('Unable to initialize apps: $error');
    });
  }

  @override
  void dispose() {
    _memoryResources?.unregister(this);
    _appsSubscription?.cancel();
    unawaited(_imagePool.close());
    _iconCache.clear();
    _bannerCache.clear();
    _settingsService?.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> _init() async {
    await _refreshState(shouldNotifyListeners: false);
    if (isDisposed) return;
    if (_database.wasCreated && _categoriesById.isEmpty) {
      await _initDefaultCategories();
    } else {
      await _ensureTvAppsSectionOrder();
    }

    if (isDisposed) return;
    _appsSubscription = _fLauncherChannel.addAppsChangedListener((event) async {
      if (isDisposed) return;
      String? changedPackageName;
      if (event.containsKey('packageName')) {
        changedPackageName = event['packageName'];
      } else if (event.containsKey('activityInfo')) {
        changedPackageName = event['activityInfo']['packageName'];
      }

      if (changedPackageName != null) {
        _iconCache.remove(changedPackageName);
        _bannerCache.remove(changedPackageName);
      }

      switch (event["action"]) {
        case "CATALOG_CHANGED":
          await refreshState();
          return;
        case "PACKAGE_ADDED":
        case "PACKAGE_CHANGED":
          Map<dynamic, dynamic> applicationInfo = event['activityInfo'];
          await _database.persistApps([_buildAppCompanion(applicationInfo)]);

          if (isDisposed) return;
          App newApp = App.fromSystem(applicationInfo);
          App? existingApp = _applications[newApp.packageName];

          if (existingApp != null) {
            newApp.hidden = existingApp.hidden;
            newApp.categoryOrders = Map.from(existingApp.categoryOrders);
            for (int categoryId in newApp.categoryOrders.keys) {
              final category = _categoriesById[categoryId];
              if (category != null) {
                int index = category.applications.indexOf(existingApp);
                if (index != -1) {
                  category.applications[index] = newApp;
                } else {
                  category.applications.add(newApp);
                }
              }
            }
            _applications[newApp.packageName] = newApp;
          } else {
            _applications[newApp.packageName] = newApp;
            final targetCategory =
                newApp.isLaunchable ? _findTargetCategoryForNewApp(newApp.sideloaded) : null;
            if (targetCategory != null) {
              await addToCategory(newApp, targetCategory,
                  shouldNotifyListeners: false);
            }
          }
          break;
        case "PACKAGES_AVAILABLE":
          List<dynamic> applicationsInfo = event["activitiesInfo"];
          await _database
              .persistApps((applicationsInfo).map(_buildAppCompanion));

          if (isDisposed) return;
          for (Map<dynamic, dynamic> applicationInfo in applicationsInfo) {
            App newApp = App.fromSystem(applicationInfo);
            App? existingApp = _applications[newApp.packageName];

            if (existingApp != null) {
              newApp.hidden = existingApp.hidden;
              newApp.categoryOrders = Map.from(existingApp.categoryOrders);
              for (int categoryId in newApp.categoryOrders.keys) {
                final category = _categoriesById[categoryId];
                if (category != null) {
                  int index = category.applications.indexOf(existingApp);
                  if (index != -1) {
                    category.applications[index] = newApp;
                  } else {
                    category.applications.add(newApp);
                  }
                }
              }
              _applications[newApp.packageName] = newApp;
            } else {
              _applications[newApp.packageName] = newApp;
            }
            _iconCache.remove(newApp.packageName);
            _bannerCache.remove(newApp.packageName);
          }
          break;
        case "PACKAGE_REMOVED":
          String packageName = event['packageName'];
          await _database.deleteApps([packageName]);

          if (isDisposed) return;
          // Clear icon cache for removed app
          _iconCache.remove(packageName);
          _bannerCache.remove(packageName);

          App? application = _applications.remove(packageName);

          if (application != null) {
            for (int categoryId in application.categoryOrders.keys) {
              final category = _categoriesById[categoryId];
              if (category != null) {
                category.applications.remove(application);
              }
            }
          }
          break;
      }

      notifyListeners();
    });

    _initialized = true;
    notifyListeners();

  }

  AppsCompanion _buildAppCompanion(dynamic data) {
    String? version = data["version"];
    version ??= "";

    return AppsCompanion(
        packageName: Value(data["packageName"]),
        name: Value(data["name"]),
        version: Value(version),
        hidden: const Value.absent());
  }

  /// Restore section defaults atomically without changing app data or statistics.
  Future<void> resetSections() async {
    await _database.transaction(() async {
      await _database.delete(_database.appsCategories).go();
      await _database.delete(_database.launcherSpacers).go();
      await _database.delete(_database.categories).go();
      final defaults = [
        ('All Apps', 'all_apps', CategoryType.grid),
        ('TV Apps', 'tv_apps', CategoryType.grid),
        ('Non-TV Apps', 'other_apps', Category.Type),
        ('Favorites', 'favorites', Category.Type),
      ];
      for (var i = 0; i < defaults.length; i++) {
        final (name, key, type) = defaults[i];
        final id = await _database.insertCategory(
          CategoriesCompanion.insert(
            name: name,
            systemKey: Value(key),
            order: i,
            type: Value(type),
            sort: Value(key == 'all_apps' ? CategorySort.alphabetical : Category.Sort),
          ),
        );
        if (key == 'tv_apps' || key == 'other_apps') {
          final apps =
              _applications.values
                  .where((app) => app.isLaunchable && app.sideloaded == (key == 'other_apps'))
                  .toList()
                ..sort((a, b) => a.packageName.compareTo(b.packageName));
          await _database.insertAppsCategories([
            for (var j = 0; j < apps.length; j++)
              AppsCategoriesCompanion.insert(
                categoryId: id,
                appPackageName: apps[j].packageName,
                order: j,
              ),
          ]);
        }
      }
    });
    await refreshState();
  }

  Future<void> _initDefaultCategories() => _database.transaction(() async {
    await addCategory('All Apps', systemKey: 'all_apps',
        type: CategoryType.grid, sort: CategorySort.alphabetical,
        shouldNotifyListeners: false);
    await addCategory('TV Apps', systemKey: 'tv_apps', type: CategoryType.grid,
        shouldNotifyListeners: false);
    await addCategory('Non-TV Apps', systemKey: 'other_apps',
        shouldNotifyListeners: false);
    await addCategory('Favorites', systemKey: 'favorites',
        shouldNotifyListeners: false);
  });

  /// Ensures that "TV Apps" section is placed above "Non-TV Apps" section by default.
  /// This fixes existing installs where "Non-TV Apps" was previously created at order 0.
  Future<void> _ensureTvAppsSectionOrder() async {
    final prefs = await _prefsAsync;
    const migrationKey = "tv_apps_section_order_default_v1";
    if (prefs.getBool(migrationKey) == true) {
      return;
    }

    int tvAppsIndex = -1;
    int nonTvAppsIndex = -1;

    for (int i = 0; i < _launcherSections.length; i++) {
      final section = _launcherSections[i];
      if (section is Category) {
        final name = section.name.toLowerCase();
        if (name == "tv apps" || name == "tv applications") {
          tvAppsIndex = i;
        } else if (name == "non-tv apps" || name == "non-tv applications") {
          nonTvAppsIndex = i;
        }
      }
    }

    if (tvAppsIndex != -1 &&
        nonTvAppsIndex != -1 &&
        tvAppsIndex > nonTvAppsIndex) {
      final tvAppsSection = _launcherSections.removeAt(tvAppsIndex);
      _launcherSections.insert(nonTvAppsIndex, tvAppsSection);
      await persistSectionsOrder();
      notifyListeners();
    }

    await prefs.setBool(migrationKey, true);
  }

  Future<void> refreshState() {
    clearImageCaches();
    return _refreshState(shouldNotifyListeners: true);
  }

  Future<void> _refreshState({bool shouldNotifyListeners = true}) async {
    if (isDisposed) return;
    Future<List<App>> appsFromDatabaseFuture = _database.getApplications();
    Future<List<AppCategory>> appsCategoriesFuture =
        _database.getAppsCategories();
    Future<List<Category>> categoriesFuture = _database.getCategories();
    Future<List<LauncherSpacer>> spacersFuture = _database.getLauncherSpacers();
    List<Map<dynamic, dynamic>> appsFromSystem =
        await _fLauncherChannel.getApplications();
    if (isDisposed) return;
    Iterable<MapEntry<String, (Map, AppsCompanion)>> appEntries =
        appsFromSystem.map((appFromSystem) => MapEntry(
            appFromSystem['packageName'],
            (appFromSystem, _buildAppCompanion(appFromSystem))));
    Map<String, (Map, AppsCompanion)> appsFromSystemByPackageName =
        Map.fromEntries(appEntries);

    await _database.transaction(() async {
      await _database.persistApps(
          appsFromSystemByPackageName.values.map((record) => record.$2));
    });

    appsFromDatabaseFuture = _database.getApplications();

    await Future.wait([
      appsFromDatabaseFuture,
      appsCategoriesFuture,
      categoriesFuture,
      spacersFuture
    ]);

    List<App> appsFromDatabase = await appsFromDatabaseFuture;
    List<AppCategory> appsCategories = await appsCategoriesFuture;
    List<Category> categories = await categoriesFuture;
    List<LauncherSpacer> spacers = await spacersFuture;

    if (isDisposed) return;
    _categoriesById = Map.fromEntries(
        categories.map((category) => MapEntry(category.id, category)));
    _applications = Map.fromEntries(appsFromDatabase
        .where((application) =>
            appsFromSystemByPackageName.containsKey(application.packageName))
        .map((application) => MapEntry(application.packageName, application)));

    _launcherSections.clear();
    _launcherSections.addAll(categories);
    _launcherSections.addAll(spacers);
    _launcherSections.sort((ls0, ls1) => ls0.order.compareTo(ls1.order));

    Map<String, List<AppCategory>> appsCategoriesByPackage = {};
    if (appsCategories.isNotEmpty) {
      for (AppCategory appCategory in appsCategories) {
        (appsCategoriesByPackage[appCategory.appPackageName] ??= [])
            .add(appCategory);
      }
    }

    final List<App> orphanedApps = [];

    for (App application in _applications.values) {
      Map? applicationFromSystem =
          appsFromSystemByPackageName[application.packageName]?.$1;

      if (applicationFromSystem != null) {
        if (applicationFromSystem.containsKey('action')) {
          application.action = applicationFromSystem['action'];
        }
        application.isSystem = applicationFromSystem['system'] == true;
        application.isLaunchable = applicationFromSystem['launchable'] != false;
        if (applicationFromSystem.containsKey('sideloaded')) {
          application.sideloaded = applicationFromSystem['sideloaded'];
        }
      }

      if (_categoriesById.isNotEmpty) {
        List<AppCategory>? currentApplicationCategories =
            appsCategoriesByPackage[application.packageName];

        if (currentApplicationCategories != null) {
          for (AppCategory appCategory in currentApplicationCategories) {
            final category = _categoriesById[appCategory.categoryId];
            if (category != null) {
              application.categoryOrders[category.id] = appCategory.order;
              category.applications.add(application);
            }
          }
        } else {
          orphanedApps.add(application);
        }
      }
    }

    if (orphanedApps.isNotEmpty) {
      await _repairOrphanedAppCategories(orphanedApps);
    }

    for (Category category in _categoriesById.values) {
      sortCategory(category);
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void sortCategory(Category category) {
    if (category.sort == CategorySort.alphabetical) {
      category.applications
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (category.sort == CategorySort.mostUsed) {
      category.applications.sort((a, b) {
        final frequency = b.launchCount.compareTo(a.launchCount);
        return frequency != 0 ? frequency : a.packageName.compareTo(b.packageName);
      });
    } else if (category.sort == CategorySort.lastUsed) {
      category.applications.sort((a, b) {
        final aTime =
            a.lastLaunchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastLaunchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // Descending (newest first)
      });
    } else {
      category.applications.sort((a, b) {
        final aOrder = a.categoryOrders[category.id] ?? double.infinity;
        final bOrder = b.categoryOrders[category.id] ?? double.infinity;
        if (aOrder == bOrder) {
          return a.packageName.compareTo(b.packageName);
        }
        return aOrder.compareTo(bOrder);
      });
    }
  }

  /// Assigns persisted category membership and manual order for installed apps
  /// that are missing AppsCategories rows.
  Future<void> _repairOrphanedAppCategories(Iterable<App> orphanedApps) async {
    if (orphanedApps.isEmpty || _categoriesById.isEmpty) {
      return;
    }

    final Map<int, List<App>> appsByCategoryId = {};
    for (final app in orphanedApps) {
      if (!app.isLaunchable) continue;
      final targetCategory = _findTargetCategoryForNewApp(app.sideloaded);
      if (targetCategory == null) {
        continue;
      }
      (appsByCategoryId[targetCategory.id] ??= []).add(app);
    }

    final List<AppsCategoriesCompanion> batch = [];
    for (final entry in appsByCategoryId.entries) {
      final category = _categoriesById[entry.key];
      if (category == null) {
        continue;
      }

      final sortedApps = List<App>.from(entry.value)
        ..sort((a, b) => a.packageName.compareTo(b.packageName));
      int nextOrder = await _database.nextAppCategoryOrder(category.id) ?? 0;

      for (final app in sortedApps) {
        batch.add(AppsCategoriesCompanion.insert(
          categoryId: category.id,
          appPackageName: app.packageName,
          order: nextOrder,
        ));
        app.categoryOrders[category.id] = nextOrder;
        if (!app.hidden) {
          category.applications.add(app);
        }
        nextOrder++;
      }
    }

    if (batch.isNotEmpty) {
      await _database.insertAppsCategories(batch);
    }
  }

  /// Automatic placement never falls back to Favorites or a custom section.
  Category? _findTargetCategoryForNewApp(bool isSideloaded) =>
      _categoriesById.values.firstWhereOrNull((category) =>
          category.systemKey == (isSideloaded ? 'other_apps' : 'tv_apps'));

  Future<Uint8List> getAppBanner(String packageName) =>
      _loadImage('banner:$packageName', () => _readAppBanner(packageName));

  Future<Uint8List> _readAppBanner(String packageName) async {
    final generation = _imageGeneration;
    if (isDisposed) return Uint8List(0);
    if (_bannerCache.containsKey(packageName)) {
      return _bannerCache[packageName]!;
    }

    try {
      final prefs = await _prefsAsync;
      if (isDisposed) return Uint8List(0);
      final customBannerPath = prefs.getString('custom_banner_$packageName');
      if (customBannerPath != null) {
        final file = File(customBannerPath);
        if (await file.exists()) {
          final bytes = await readBoundedImage(file.openRead());
          await validateImageBytes(bytes);
          if (!isDisposed && generation == _imageGeneration) _bannerCache[packageName] = bytes;
          return _bannerCache[packageName] ?? bytes;
        }
      }
    } on ImageInputException {
      if (!isDisposed && generation == _imageGeneration) _bannerCache[packageName] = Uint8List(0);
      return Uint8List(0); // Keep the original file and preference; show the app icon instead.
    } on FileSystemException {
      // File was deleted between check and read - clear stale reference
      final prefs = await _prefsAsync;
      await prefs.remove('custom_banner_$packageName');
    } catch (_) {
      // Ignore other errors reading custom banner
    }

    if (isDisposed) return Uint8List(0);
    final bytes = await _fLauncherChannel.getApplicationBanner(packageName);
    if (!isDisposed && generation == _imageGeneration) {
      _bannerCache[packageName] = bytes;
    }
    return _bannerCache[packageName] ?? bytes;
  }

  Future<void> setCustomAppBanner(String packageName, String imagePath) async {
    final bytes = await readBoundedImage(File(imagePath).openRead());
    await validateImageBytes(bytes);
    if (isDisposed) return;
    final prefs = await _prefsAsync;
    await prefs.setString('custom_banner_$packageName', imagePath);
    _bannerCache.remove(packageName);
    notifyListeners();
  }

  Future<void> removeCustomAppBanner(String packageName) async {
    final prefs = await _prefsAsync;
    final customBannerPath = prefs.getString('custom_banner_$packageName');
    if (customBannerPath != null) {
      try {
        await File(customBannerPath).delete();
      } catch (_) {
        // Ignore file deletion errors
      }
    }
    await prefs.remove('custom_banner_$packageName');
    _bannerCache.remove(packageName);
    notifyListeners();
  }

  Future<bool> hasCustomBanner(String packageName) async {
    final prefs = await _prefsAsync;
    return prefs.containsKey('custom_banner_$packageName');
  }

  App? getApp(String packageName) => _applications[packageName];

  Future<Uint8List> getAppIcon(String packageName) =>
      _loadImage('icon:$packageName', () => _readAppIcon(packageName));

  Future<Uint8List> _readAppIcon(String packageName) async {
    final generation = _imageGeneration;
    if (isDisposed) return Uint8List(0);
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName]!;
    }
    final bytes = await _fLauncherChannel.getApplicationIcon(packageName);
    if (!isDisposed && generation == _imageGeneration) {
      _iconCache[packageName] = bytes;
    }
    return _iconCache[packageName] ?? bytes;
  }

  Future<bool> launchApp(App app) async {
    final bool launched;
    try {
      launched = app.action == null
          ? await _fLauncherChannel.launchApp(app.packageName)
          : await _fLauncherChannel.launchActivityFromAction(app.action!);
    } catch (error) {
      debugPrint('Failed to launch ${app.packageName}: $error');
      return false;
    }
    if (!launched || isDisposed) return false;
    await recordAppLaunch(app.packageName, fallback: app);
    return true;
  }

  Future<void> _launchStatisticsWrite = Future.value();

  Future<void> recordAppLaunch(String packageName, {App? fallback}) {
    final write = _launchStatisticsWrite.then((_) async {
      if (isDisposed) return;
      final app = _applications[packageName] ?? fallback;
      if (app == null) return;
      final time = DateTime.now();
      final count = app.launchCount + 1;
      await _database.updateApp(packageName, AppsCompanion(
        lastLaunchedAt: Value(time), launchCount: Value(count)));
      if (isDisposed) return;
      app.lastLaunchedAt = time;
      app.launchCount = count;
      if (fallback != null) {
        fallback.lastLaunchedAt = time;
        fallback.launchCount = count;
      }
      for (final category in _categoriesById.values) {
        if (category.sort == CategorySort.lastUsed || category.sort == CategorySort.mostUsed) {
          sortCategory(category);
        }
      }
      notifyListeners();
    });
    _launchStatisticsWrite = write.catchError((Object error) {
      debugPrint('Failed to persist launch statistics: ${error.runtimeType}');
    });
    return _launchStatisticsWrite;
  }

  Future<void> openAppInfo(App app) =>
      _fLauncherChannel.openAppInfo(app.packageName);

  Future<void> uninstallApp(App app) =>
      _fLauncherChannel.uninstallApp(app.packageName);

  Future<void> openSettings() => _fLauncherChannel.openSettings();

  Future<bool> isDefaultLauncher() => _fLauncherChannel.isDefaultLauncher();

  Future<void> startAmbientMode() => _fLauncherChannel.startAmbientMode();

  Future<void> addToCategory(App app, Category category,
      {bool shouldNotifyListeners = true}) async {
    await addAllToCategory([app], category,
        shouldNotifyListeners: shouldNotifyListeners);
  }

  Future<void> addAllToCategory(Iterable<App> apps, Category category,
      {bool shouldNotifyListeners = true}) async {
    if (apps.isEmpty) return;

    final categoryFound = _categoriesById[category.id];
    if (categoryFound == null || categoryFound.isAutomatic) return;

    int nextOrder = await _database.nextAppCategoryOrder(categoryFound.id) ?? 0;
    List<AppsCategoriesCompanion> batch = [];

    final existingPackages = categoryFound.applications.map((app) => app.packageName).toSet();
    for (final candidate in apps) {
      if (!existingPackages.add(candidate.packageName)) continue;
      final app = _applications[candidate.packageName] ?? candidate;
      batch.add(AppsCategoriesCompanion.insert(
        categoryId: categoryFound.id,
        appPackageName: app.packageName,
        order: nextOrder,
      ));
      app.categoryOrders[categoryFound.id] = nextOrder;
      categoryFound.applications.add(app);
      nextOrder++;
    }

    await _database.insertAppsCategories(batch);

    sortCategory(
        categoryFound); // also for new apps, which arrive without notify
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> removeFromCategory(App application, Category category) async {
    // Computed catalogs cannot be edited through manual membership actions.
    if ((_categoriesById[category.id] ?? category).isAutomatic) return;
    await _database.deleteAppCategory(category.id, application.packageName);
    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      application.categoryOrders.remove(categoryFound.id);
      _applications[application.packageName]?.categoryOrders.remove(categoryFound.id);
      categoryFound.applications.removeWhere((app) => app.packageName == application.packageName);

      notifyListeners();
    }
  }

  /// Refresh a computed category without changing manual memberships.
  Future<void> autoPopulateCategory(Category category) async {
    final actual = _categoriesById[category.id];
    if (actual == null || !actual.isAutomatic) return;
    _displayCategory(actual);
    notifyListeners();
  }

  // === FAVORITES METHODS ===

  /// Gets the Favorites category, creating it if it doesn't exist
  Future<Category> getOrCreateFavoritesCategory() async {
    // Look for existing Favorites category
    Category? favorites = _categoriesById.values
        .firstWhereOrNull((category) => category.systemKey == 'favorites');

    if (favorites != null) {
      return favorites;
    }

    // Create Favorites category if it doesn't exist
    int categoryId =
        await addCategory('Favorites', systemKey: 'favorites', shouldNotifyListeners: false);
    return _categoriesById[categoryId]!;
  }

  /// Checks if an app is in the Favorites category
  bool isAppInFavorites(App app) {
    Category? favorites = _categoriesById.values
        .firstWhereOrNull((category) => category.systemKey == 'favorites');

    if (favorites == null) {
      return false;
    }

    return favorites.applications.any((a) => a.packageName == app.packageName);
  }

  /// Adds an app to Favorites
  Future<void> addToFavorites(App app) async {
    Category favorites = await getOrCreateFavoritesCategory();

    // Check if already in favorites
    if (!favorites.applications.any((a) => a.packageName == app.packageName)) {
      await addToCategory(app, favorites);
    }
  }

  /// Removes an app from Favorites
  Future<void> removeFromFavorites(App app) async {
    Category? favorites = _categoriesById.values
        .firstWhereOrNull((category) => category.systemKey == 'favorites');

    if (favorites != null) {
      await removeFromCategory(app, favorites);
    }
  }

  /// Toggles an app in/out of Favorites
  Future<void> toggleFavorite(App app) async {
    if (isAppInFavorites(app)) {
      await removeFromFavorites(app);
    } else {
      await addToFavorites(app);
    }
  }

  Future<void> saveApplicationOrderInCategory(Category category) async {
    if (!_categoriesById.containsKey(category.id)) {
      return;
    }

    Category categoryFound = _categoriesById[category.id]!;
    List<App> applications = categoryFound.applications;
    List<AppsCategoriesCompanion> orderedAppCategories = [];

    for (int i = 0; i < applications.length; ++i) {
      applications[i].categoryOrders[categoryFound.id] = i;
      orderedAppCategories.add(AppsCategoriesCompanion(
        categoryId: Value(categoryFound.id),
        appPackageName: Value(applications[i].packageName),
        order: Value(i),
      ));
    }
    await _database.replaceAppsCategories(orderedAppCategories);
    notifyListeners();
  }

  Future<void> moveAppToAdjacentCategory(
      App app, Category currentCategory, AxisDirection direction) async {
    int currentSectionIndex = _launcherSections.indexOf(currentCategory);
    if (currentSectionIndex == -1) {
      return;
    }

    Category? targetCategory;

    // Find next valid category (skip spacers)
    if (direction == AxisDirection.down) {
      for (int i = currentSectionIndex + 1; i < _launcherSections.length; i++) {
        if (_launcherSections[i] is Category) {
          targetCategory = _launcherSections[i] as Category;
          break;
        }
      }
    } else if (direction == AxisDirection.up) {
      for (int i = currentSectionIndex - 1; i >= 0; i--) {
        if (_launcherSections[i] is Category) {
          targetCategory = _launcherSections[i] as Category;
          break;
        }
      }
    }

    if (targetCategory == null) {
      return;
    }

    // Remove from current
    await removeFromCategory(app, currentCategory);

    // Add to target
    // DB Insert Logic
    // 1. Get current items in target
    List<App> targetApps = targetCategory.applications;

    // 2. Adjust local list
    if (direction == AxisDirection.down) {
      targetApps.insert(0, app); // Insert at top
    } else {
      targetApps.add(app); // Insert at bottom
    }

    int newIndex = direction == AxisDirection.down ? 0 : targetApps.length - 1;
    setPendingReorderFocus(app.packageName, targetCategory.id, newIndex);

    // 3. Update orders for all items in target category
    List<AppsCategoriesCompanion> orderedAppCategories = [];
    for (int i = 0; i < targetApps.length; ++i) {
      App a = targetApps[i];
      a.categoryOrders[targetCategory.id] = i; // Update local map
      orderedAppCategories.add(AppsCategoriesCompanion(
        categoryId: Value(targetCategory.id),
        appPackageName: Value(a.packageName),
        order: Value(i),
      ));
    }

    // 4. Batch DB update
    await _database.replaceAppsCategories(orderedAppCategories);

    notifyListeners();
  }

  void reorderApplication(Category category, int oldIndex, int newIndex) {
    if (!_categoriesById.containsKey(category.id)) {
      return;
    }
    Category categoryFound = _categoriesById[category.id]!;
    List<App> applications = categoryFound.applications;
    App application = applications.removeAt(oldIndex);
    applications.insert(newIndex, application);

    notifyListeners();
  }

  void cancelReorderApplication(Category category) {
    if (!_categoriesById.containsKey(category.id)) {
      return;
    }
    Category categoryFound = _categoriesById[category.id]!;
    sortCategory(categoryFound);
    notifyListeners();
  }

  Future<int> addCategory(String categoryName,
      {String? systemKey,
      CategorySort sort = Category.Sort,
      CategoryType type = Category.Type,
      int columnsCount = Category.ColumnsCount,
      int rowHeight = Category.RowHeight,
      bool shouldNotifyListeners = true}) async {
    categoryName = Category.normalizeName(categoryName, systemKey);
    int order = _launcherSections.length;
    int newCategoryId = -1;

    try {
      newCategoryId = await _database.transaction(() async {
        int newCategoryId = await _database.insertCategory(
            CategoriesCompanion.insert(name: categoryName, order: order, systemKey: Value(systemKey), sort: Value(sort), type: Value(type), columnsCount: Value(columnsCount), rowHeight: Value(rowHeight)));
        return newCategoryId;
      });

      Category newCategory = Category(
          systemKey: systemKey,
          id: newCategoryId,
          name: categoryName,
          sort: sort,
          type: type,
          columnsCount: columnsCount,
          rowHeight: rowHeight,
          order: order);

      _categoriesById[newCategoryId] = newCategory;
      _launcherSections.add(newCategory);

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (ex) {
      // Preserve the existing fallback when category creation fails.
    }

    return newCategoryId;
  }

  Future<void> updateCategory(int categoryId, String name, CategorySort sort,
      CategoryType type, int columnsCount, int rowHeight,
      {bool shouldNotifyListeners = true}) async {
    Category? category = _categoriesById[categoryId];
    assert(category != null);
    name = Category.normalizeName(name, category?.systemKey);

    await _database.updateCategory(
        categoryId,
        CategoriesCompanion(
            name: Value(name),
            sort: Value(sort),
            type: Value(type),
            columnsCount: Value(columnsCount),
            rowHeight: Value(rowHeight)));

    CategorySort oldSort = category!.sort;

    category.name = name;
    category.sort = sort;
    category.type = type;
    category.columnsCount = columnsCount;
    category.rowHeight = rowHeight;

    if (oldSort != sort) {
      sortCategory(category);
    }

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> addSpacer(int height) async {
    int order = launcherSections.length;
    int spacerId = await _database.insertSpacer(
        LauncherSpacersCompanion.insert(height: height, order: order));

    _launcherSections
        .add(LauncherSpacer(id: spacerId, height: height, order: order));

    notifyListeners();
  }

  Future<void> updateSpacerHeight(LauncherSpacer spacer, int height) async {
    await _database.updateSpacer(
        spacer.id, LauncherSpacersCompanion(height: Value(height)));

    spacer.height = height;
    notifyListeners();
  }

  Future<void> renameCategory(Category category, String categoryName) async {
    categoryName = Category.normalizeName(categoryName, (_categoriesById[category.id] ?? category).systemKey);
    await _database.updateCategory(
        category.id, CategoriesCompanion(name: Value(categoryName)));

    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      categoryFound.name = categoryName;
        notifyListeners();
    }
  }

  Future<void> deleteSection(int index) async {
    assert(index < _launcherSections.length);

    LauncherSection section = _launcherSections[index];
    if (section is Category) {
      if (section.isSystem || _categoriesById.length <= 1 || (section.visible && _categoriesById.values.where((c) => c.visible).length <= 1)) return;
      final affected = <String, App>{
        for (final app in section.applications) app.packageName: app,
        for (final app in _applications.values.where((app) => app.categoryOrders.containsKey(section.id))) app.packageName: app,
      }.values;

      await _database.transaction(() => _database.deleteCategory(section.id));
      for (final app in affected) {
        app.categoryOrders.remove(section.id);
      }
      _categoriesById.remove(section.id);
    } else {
      await _database.deleteSpacer(section.id);
    }

    _launcherSections.removeAt(index);

    notifyListeners();
  }

  Future<bool> setCategoryVisible(int id, bool visible) async {
    // Keep validation and update in the database transaction so simultaneous
    // requests cannot hide the last visible category.
    final changed = await _database.transaction(() async {
      final stored = await _database.getCategories();
      final category = stored.firstWhereOrNull((c) => c.id == id);
      if (category == null) return false;
      if (!visible && category.visible && stored.where((c) => c.visible).length <= 1) return false;
      await _database.updateCategory(id, CategoriesCompanion(visible: Value(visible)));
      return true;
    });
    if (changed) {
      _categoriesById[id]?.visible = visible;
      notifyListeners();
    }
    return changed;
  }

  void moveSectionInMemory(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _launcherSections.length ||
        newIndex < 0 ||
        newIndex >= _launcherSections.length) {
      return;
    }

    final section = _launcherSections.removeAt(oldIndex);
    _launcherSections.insert(newIndex, section);
    notifyListeners();
  }

  Future<void> persistSectionsOrder() async {
    List<CategoriesCompanion> orderedCategories = [];
    List<LauncherSpacersCompanion> orderedSpacers = [];

    for (int i = 0; i < _launcherSections.length; ++i) {
      LauncherSection section = _launcherSections[i];
      // Update the order property on the object itself
      if (section is Category) {
        section.order = i;
      } else if (section is LauncherSpacer) {
        section.order = i;
      }

      if (section is Category) {
        orderedCategories
            .add(CategoriesCompanion(id: Value(section.id), order: Value(i)));
      } else {
        orderedSpacers.add(
            LauncherSpacersCompanion(id: Value(section.id), order: Value(i)));
      }
    }

    await Future.wait([
      _database.updateCategories(orderedCategories),
      _database.updateSpacers(orderedSpacers)
    ]);
  }

  Future<void> moveSection(int oldIndex, int newIndex) async {
    moveSectionInMemory(oldIndex, newIndex);
    await persistSectionsOrder();
  }

  Future<void> hideApplication(App application) async {
    await _database.updateApp(
        application.packageName, const AppsCompanion(hidden: Value(true)));

    final applicationFound = _applications[application.packageName];
    if (applicationFound != null) {
      applicationFound.hidden = true;

      notifyListeners();
    }
  }

  Future<void> showApplication(App application) async {
    if (application.packageName == _ownPackageName) {
      await _settingsService?.setHideLauncherTile(false);
    }
    if (application.packageName == 'com.android.tv.settings' ||
        application.packageName == 'com.android.settings' ||
        application.action == 'android.settings.SETTINGS') {
      await _settingsService?.setHideAndroidSettingsTile(false);
    }
    await _database.updateApp(
        application.packageName, const AppsCompanion(hidden: Value(false)));

    final applicationFound = _applications[application.packageName];
    if (applicationFound != null) {
      applicationFound.hidden = false;

      notifyListeners();
    }
  }

  Future<void> setCategoryType(Category category, CategoryType type,
      {bool shouldNotifyListeners = true}) async {
    await _database.updateCategory(
        category.id, CategoriesCompanion(type: Value(type)));

    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      categoryFound.type = type;

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    }
  }

  Future<void> setCategorySort(Category category, CategorySort sort) async {
    await _database.updateCategory(
        category.id, CategoriesCompanion(sort: Value(sort)));
    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      categoryFound.sort = sort;
      sortCategory(categoryFound);

      notifyListeners();
    }
  }

  Future<void> setCategoryColumnsCount(
      Category category, int columnsCount) async {
    await _database.updateCategory(
        category.id, CategoriesCompanion(columnsCount: Value(columnsCount)));

    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      categoryFound.columnsCount = columnsCount;

      notifyListeners();
    }
  }

  Future<void> setCategoryRowHeight(Category category, int rowHeight) async {
    await _database.updateCategory(
        category.id, CategoriesCompanion(rowHeight: Value(rowHeight)));

    final categoryFound = _categoriesById[category.id];
    if (categoryFound != null) {
      categoryFound.rowHeight = rowHeight;
      notifyListeners();
    }
  }
}

