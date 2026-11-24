import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('secondary engine keeps its small image budget after profile changes', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings, secondaryEngine: true);
    for (final economy in [false, true, false]) {
      await settings.setMemorySaverEnabled(economy);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes, 8 * 1024 * 1024);
      expect(PaintingBinding.instance.imageCache.maximumSize, 20);
    }
    resources.dispose();
    settings.dispose();
  });
  test('manual limits survive restart and economy, and only local limits reset', () async {
    SharedPreferences.setMockInitialValues({'poster_cache_feeds_ram': 128, 'poster_cache_watch_next_disk': 128, 'other': 'keep'});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final resources = MemoryResources(settings: settings);
    addTearDown(settings.dispose);
    addTearDown(resources.dispose);
    var clears = 0;
    resources.register(Object(), clear: () => clears++, stats: () => const MemoryCacheStats(0, 0));
    await settings.setMemoryLimit(MemoryLimit.decodedApps, 32);
    expect(PaintingBinding.instance.imageCache.maximumSizeBytes, 62 * 1024 * 1024);
    expect(clears, 0);
    await settings.setClearCachesOnBackground(true);
    resources.didChangeAppLifecycleState(AppLifecycleState.hidden);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(clears, 1);
    await settings.setMemorySaverEnabled(true);
    await settings.setMemoryLimit(MemoryLimit.feedRam, 4);
    await settings.resetMemoryLimits();
    final restarted = SettingsService(prefs);
    addTearDown(restarted.dispose);
    for (final limit in MemoryLimit.values) {
      expect(restarted.memoryLimit(limit), limit.economy);
    }
    await restarted.setMemorySaverEnabled(false);
    expect(restarted.memoryLimit(MemoryLimit.feedRam), 128);
    expect(restarted.memoryLimit(MemoryLimit.watchDisk), 128);
    expect(restarted.memoryLimit(MemoryLimit.decodedApps), 32);
    expect(restarted.clearCachesOnBackground, isTrue);
    await restarted.resetMemoryLimits();
    for (final limit in MemoryLimit.values) {
      expect(restarted.memoryLimit(limit), limit.normal);
    }
    expect(restarted.clearCachesOnBackground, isFalse);
    expect(prefs.getString('other'), 'keep');
  });

  test('feature snapshots aggregate providers without double counting and retain old snapshots', () {
    final resources = MemoryResources();
    final owner = Object();
    var icons = 100;
    resources.register(owner, clear: () => icons = 0,
        stats: () => MemoryCacheStats(icons + 200, 3),
        breakdown: () => {
          MemoryCacheKind.appIcons: MemoryCacheStats(icons, 1),
          MemoryCacheKind.appBanners: const MemoryCacheStats(200, 2),
        });
    resources.register(Object(), clear: () {}, stats: () => const MemoryCacheStats(50, 1));
    final snapshot = resources.cacheBreakdown;
    expect(snapshot[MemoryCacheKind.appIcons]!.bytes, 100);
    expect(snapshot[MemoryCacheKind.other]!.bytes, 50);
    expect(snapshot.values.fold<int>(0, (sum, stats) => sum + stats.bytes), resources.encodedImages.bytes);
    resources.clearRecoverableCaches();
    expect(resources.cacheBreakdown[MemoryCacheKind.appIcons]!.bytes, 0);
    expect(snapshot[MemoryCacheKind.appIcons]!.bytes, 100);
    resources.unregister(owner);
    expect(resources.cacheBreakdown[MemoryCacheKind.appBanners]!.bytes, 0);
    resources.dispose();
  });
  test(
      'saving profile applies immediately and survives compatible settings import',
      () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    var economy = false;
    resources.register(Object(),
        clear: () {},
        stats: () => const MemoryCacheStats(0, 0),
        configure: (value) => economy = value);
    await settings.setMemorySaverEnabled(true);
    expect(economy, isTrue);
    expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes, 16 * 1024 * 1024);
    await settings.importSettingsMap({'show_time_in_status_bar': true});
    expect(settings.memorySaverEnabled, isTrue);
    await settings.importSettingsMap({'memory_saver_enabled': 'wrong'});
    expect(settings.memorySaverEnabled, isTrue);
    await settings.setMemorySaverEnabled(false);
    expect(economy, isFalse);
    expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes, 50 * 1024 * 1024);
    resources.dispose();
    settings.dispose();
  });

  test(
      'pressure clears caches but normal app switching retains them',
      () {
    var count = 0;
    var bytes = 100;
    final owner = Object();
    final resources = MemoryResources();
    resources.register(owner,
        clear: () {
          count++;
          bytes = 0;
        },
        stats: () => MemoryCacheStats(bytes, 1));
    expect(resources.encodedImages.bytes, 100);
    resources.didHaveMemoryPressure();
    expect(resources.encodedImages.bytes, 0);
    resources.didChangeAppLifecycleState(AppLifecycleState.hidden);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(count, 1);
    resources.didChangeAppLifecycleState(AppLifecycleState.resumed);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(count, 1);
    resources.unregister(owner);
    resources.clearRecoverableCaches();
    expect(count, 1);
    resources.dispose();
  });

  test('economy clears once per background transition', () async {
    SharedPreferences.setMockInitialValues({'memory_saver_enabled': true});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    var count = 0;
    resources.register(Object(), clear: () => count++,
        stats: () => const MemoryCacheStats(0, 0));
    resources.didChangeAppLifecycleState(AppLifecycleState.hidden);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(count, 1);
    resources.didChangeAppLifecycleState(AppLifecycleState.resumed);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(count, 2);
    resources.dispose();
    settings.dispose();
  });
}
