import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/diagnostics/economy_diagnostics.dart';
import 'package:flauncher/content_image.dart';
import 'package:flauncher/image_byte_cache.dart';
import 'package:flauncher/main.dart' as launcher;
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/appearance_surface.dart';
import 'package:flauncher/widgets/tile_theme_outline.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Isolated fixture using the production rendering widgets/LRU. Not a substitute
/// for a real catalogue: measures saturated caches and effects separately.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hardware = (await Process.run('/system/bin/getprop', [
    'ro.hardware',
  ])).stdout.toString().trim();
  if (!['ranchu', 'goldfish'].contains(hardware)) {
    final model = (await Process.run('/system/bin/getprop', [
      'ro.product.model',
    ])).stdout.toString().trim();
    if (!const bool.fromEnvironment('ALLOW_TCL_PROBE') ||
        model != 'Smart TV Pro') {
      throw StateError('Explicit TCL probe build required');
    }
  }
  final external = (await getExternalStorageDirectory())!;
  final configFile = File('${external.path}/economy-probe.json');
  final config = configFile.existsSync()
      ? jsonDecode(await configFile.readAsString()) as Map<String, dynamic>
      : <String, dynamic>{};
  if (config['scenario'] == 'cleanup') {
    SharedPreferences.setPrefix('economy_probe.');
    await (await SharedPreferences.getInstance()).clear();
    final fixture = Directory(
      '${(await getTemporaryDirectory()).path}/economy-probe-fixture',
    );
    if (fixture.existsSync()) await fixture.delete(recursive: true);
    await configFile.delete();
    debugPrint('CUTE_FIXTURE_CLEANUP PASS');
    // SharedPreferences cannot change its prefix after initialization. Finish
    // this isolated process; the ordinary APK starts with its default prefix.
    await SystemNavigator.pop();
    return;
  }
  if (config['scenario'] == 'launcher') {
    await launcher.main();
    return;
  }
  SharedPreferences.setPrefix('economy_probe.');
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  final settings = SettingsService(prefs);
  await settings.setMemorySaverEnabled(config['economy'] == true);
  await settings.setAppHighlightAnimationEnabled(config['heavy'] == true);
  final resources = MemoryResources(settings: settings);
  final directory = Directory(
    '${(await getTemporaryDirectory()).path}/economy-probe-fixture',
  );
  await directory.create(recursive: true);
  final count = config['saturated'] == true ? 144 : 12;
  for (var i = 0; i < count; i++) {
    final file = File('${directory.path}/$i.png');
    if (file.existsSync()) continue;
    final random = Random(i + 2400);
    final pixels = Uint8List(320 * 180 * 4);
    for (var p = 0; p < pixels.length; p += 4) {
      pixels[p] = random.nextInt(256);
      pixels[p + 1] = random.nextInt(256);
      pixels[p + 2] = random.nextInt(256);
      pixels[p + 3] = 255;
    }
    final complete = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      320,
      180,
      ui.PixelFormat.rgba8888,
      complete.complete,
    );
    final image = await complete.future;
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    image.dispose();
  }
  debugPrint(
    'CUTE_FIXTURE ${jsonEncode({'count': count, 'heavy': config['heavy'] == true, 'economy': resources.economyEnabled, 'source_pixels': '320x180', 'bytes': await File('${directory.path}/0.png').length()})}',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: resources),
      ],
      child: _withDiagnostics(
        config,
        MaterialApp(
          theme: ThemeData.dark(),
          home: _Fixture(
            directory: directory,
            count: count,
            heavy: config['heavy'] == true,
          ),
        ),
      ),
    ),
  );
}

Widget _withDiagnostics(Map<String, dynamic> config, Widget child) =>
    config['diagnostics'] == false ? child : EconomyDiagnostics(child: child);

class _Fixture extends StatefulWidget {
  final Directory directory;
  final int count;
  final bool heavy;
  const _Fixture({
    required this.directory,
    required this.count,
    required this.heavy,
  });
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> with WidgetsBindingObserver {
  final _cache = ImageByteCache(maximumBytes: 6 * 1024 * 1024);
  final _loads = <(int, int), Future<Uint8List>>{};
  final _lastImages = <int, ImageProvider>{};
  int _generation = 0;
  Timer? _timer;
  MemoryResources? _resources;
  int _offset = 0;
  int _focus = 0;
  bool _moving = true;
  bool _foreground = true;
  int _reads = 0;

  void _clearCache() {
    _generation++;
    _cache.clear();
    _loads.clear();
  }

  Future<Uint8List?> _load(int index) {
    final cached = _cache['$index'];
    if (cached != null) return Future.value(cached);
    if (!_foreground || _resources?.isForeground == false) {
      return Future.value(null);
    }
    final generation = _generation;
    final key = (generation, index);
    return _loads.putIfAbsent(key, () async {
      try {
        _reads++;
        final bytes = await File('${widget.directory.path}/$index.png')
            .readAsBytes();
        if (mounted &&
            generation == _generation &&
            _foreground &&
            _resources!.isForeground) {
          _cache['$index'] = bytes;
        }
        return bytes;
      } finally {
        _loads.remove(key);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _moving && _foreground) {
        setState(() {
          _offset = (_offset + 6) % widget.count;
          _focus = (_focus + 1) % 12;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resources != null) return;
    _resources = context.read<MemoryResources>();
    _resources!.register(
      this,
      clear: _clearCache,
      stats: () => MemoryCacheStats(_cache.byteCount, _cache.length),
      activity: () => {
        ..._cache.activity,
        'file_reads': _reads,
        'pending_loads': _loads.length,
      },
      configure: (economy) =>
          _cache.maximumBytes = (economy ? 2 : 6) * 1024 * 1024,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _resources?.unregister(this);
    _cache.clear();
    _lastImages.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<MemoryResources>().economyEnabled;
    final appearance = widget.heavy
        ? const TileAppearance({'blurTiles': true, 'opacity': .7, 'shadow': 16})
        : const TileAppearance();
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            setState(() => _moving = !_moving);
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() => _focus = (_focus + 1) % 12);
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() => _focus = (_focus + 11) % 12);
          }
          return KeyEventResult.handled;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: WallpaperBackground(
                image: FileImage(File('${widget.directory.path}/0.png')),
                mode: widget.heavy ? 'blurred' : 'cover',
                memorySaver: economy,
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.black],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    'Economy probe • ${widget.count} images • ${widget.heavy ? 'heavy' : 'everyday'} • ${economy ? 'economy' : 'normal'}',
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      childAspectRatio: 16 / 9,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        for (var tile = 0; tile < 12; tile++)
                          RepaintBoundary(
                            child: AppearanceSurface(
                              appearance: appearance,
                              borderRadius: BorderRadius.circular(8),
                              elevation: tile == _focus ? 12 : 0,
                              focused: tile == _focus,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FutureBuilder<ImageProvider?>(
                                    future:
                                        _load((_offset + tile) % widget.count)
                                            .then(
                                              (bytes) => bytes == null
                                                  ? null
                                                  : contentImage(bytes),
                                            ),
                                    builder: (_, snapshot) {
                                      final image =
                                          snapshot.data ?? _lastImages[tile];
                                      if (snapshot.hasData) {
                                        _lastImages[tile] = snapshot.data!;
                                      }
                                      return image != null
                                          ? Image(
                                              image: ResizeImage(
                                                image,
                                                width: 320,
                                                height: 180,
                                              ),
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            )
                                          : const SizedBox();
                                    },
                                  ),
                                  if (tile == _focus && !appearance.active)
                                    TileThemeOutline(
                                      theme: 'modern',
                                      accent: Colors.cyan,
                                      pulse: widget.heavy,
                                    ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      'Tile ${(_offset + tile) % widget.count}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
