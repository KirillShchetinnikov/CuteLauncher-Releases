import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'settings_service.dart';
import 'service_lifecycle.dart';

class PlayingMedia {
  final String id, packageName, title, artist;
  final bool playing, canPlay, canPause, canNext;
  final Uint8List? artwork;
  const PlayingMedia({required this.id, required this.packageName, required this.title,
    required this.artist, required this.playing, required this.canPlay, required this.canPause,
    required this.canNext, this.artwork});
  static PlayingMedia? decode(dynamic value) {
    if (value is! Map || value['id'] is! String || (value['id'] as String).isEmpty) return null;
    String text(String key) => value[key] is String ? (value[key] as String).substring(0, (value[key] as String).length.clamp(0, 512)) : '';
    final bytes = value['artwork'];
    return PlayingMedia(id: value['id'], packageName: text('packageName'), title: text('title'),
      artist: text('artist'), playing: value['playing'] == true, canPlay: value['canPlay'] == true,
      canPause: value['canPause'] == true, canNext: value['canNext'] == true,
      artwork: bytes is Uint8List && bytes.length <= 512 * 1024 ? bytes : null);
  }
}

abstract class MediaTransport {
  Stream<dynamic> get events;
  Future<dynamic> snapshot();
  Future<bool> action(String id, String action);
  Future<bool> permission();
}
class PlatformMediaTransport implements MediaTransport {
  final MethodChannel methods;
  final EventChannel updates;
  const PlatformMediaTransport({this.methods = const MethodChannel('cutelauncher/media'),
    this.updates = const EventChannel('cutelauncher/media_events')});
  @override Stream<dynamic> get events => updates.receiveBroadcastStream();
  @override Future<dynamic> snapshot() => methods.invokeMethod('snapshot');
  @override Future<bool> action(String id, String action) async =>
    await methods.invokeMethod<bool>('action', {'id': id, 'action': action}) ?? false;
  @override Future<bool> permission() async => await methods.invokeMethod<bool>('permission') ?? false;
}

class NowPlayingService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final SettingsService settings;
  final MediaTransport transport;
  StreamSubscription<dynamic>? _subscription;
  int _generation = 0, _revision = -1;
  bool _foreground = true, _active = false;
  bool allowed = false, failed = false, busy = false, initialized = false;
  PlayingMedia? media;
  NowPlayingService(this.settings, {this.transport = const PlatformMediaTransport()}) {
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_sync);
    _sync();
  }
  void _sync() {
    final enabled = settings.showNowPlaying && _foreground && !isDisposed;
    if (enabled == _active) return;
    _active = enabled;
    _generation++;
    if (!enabled) {
      final subscription = _subscription;
      _subscription = null;
      subscription?.cancel().catchError((_) {});
      media = null;
      busy = false;
      notifyListeners();
      return;
    }
    final generation = _generation;
    initialized = false;
    _subscription = transport.events.listen((value) {
      if (!isDisposed && generation == _generation) _accept(value);
    }, onError: (_) { if (!isDisposed && generation == _generation) { failed = true; media = null; notifyListeners(); } });
    refresh();
  }
  void _accept(dynamic value) {
    if (value is! Map || value['allowed'] is! bool || value['revision'] is! int) {
      failed = true; media = null; notifyListeners(); return;
    }
    final revision = value['revision'] as int;
    if (revision < _revision) return;
    _revision = revision;
    initialized = true;
    allowed = value['allowed'];
    failed = false;
    media = allowed ? PlayingMedia.decode(value['item']) : null;
    notifyListeners();
  }
  Future<void> refresh() async {
    if (!_active || isDisposed) return;
    final generation = _generation;
    try {
      final value = await transport.snapshot();
      if (!isDisposed && generation == _generation) _accept(value);
    } catch (_) {
      if (!isDisposed && generation == _generation) { initialized = true; failed = true; media = null; notifyListeners(); }
    }
  }
  Future<bool> control(String action) async {
    final current = media;
    if (!_active || current == null || busy || isDisposed ||
      !(action == 'play' && current.canPlay || action == 'pause' && current.canPause || action == 'next' && current.canNext)) {
      return false;
    }
    final generation = _generation;
    busy = true; notifyListeners();
    try {
      final success = await transport.action(current.id, action);
      if (!isDisposed && generation == _generation) { await refresh(); failed = !success; }
      return success;
    } catch (_) { if (!isDisposed && generation == _generation) failed = true; return false; }
    finally { if (!isDisposed && generation == _generation) { busy = false; notifyListeners(); } }
  }
  Future<bool> requestPermission() async {
    try { return await transport.permission(); } catch (_) { return false; }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
  @override void dispose() {
    settings.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _foreground = false;
    _sync();
    super.dispose();
  }
}
