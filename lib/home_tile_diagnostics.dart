import 'dart:collection';

import 'app_image_type.dart';
import 'tile_image_geometry.dart';

enum HomeTileCacheClear {
  manual,
  memoryPressure,
  memoryProfile,
  backgroundEconomy,
}

enum HomeTileRead {
  background,
  obsolete,
  cacheHit,
  cacheEmpty,
  read,
  readEmpty,
}

enum HomeTileReload { mounted, reused, imageRevision, retry }

enum HomeTileRevision {
  catalogEvent,
  catalogMetadata,
  customBannerSet,
  customBannerRemoved,
}

/// A bounded session trace, separate from the general operation and error logs.
/// Reports use session-local app numbers and never include image data or paths.
class HomeTileDiagnostics {
  static const eventLimit = 512;
  static const appLimit = 256;

  final int Function() _elapsedMs;
  final bool Function()? acceptEvent;
  final _events = ListQueue<Map<String, Object>>();
  final _apps = <String, int>{};
  int _omitted = 0;
  int _generation = 0;

  HomeTileDiagnostics(this._elapsedMs, {this.acceptEvent});

  int get generation => _generation;

  void lifecycle({required bool foreground, required bool economy}) =>
      _add('lifecycle', {'foreground': foreground, 'memorySaver': economy});

  void clearCaches(HomeTileCacheClear reason) =>
      _add('cacheClear', {'reason': reason.name});

  void returnHome() => _add('home', const {});

  void revision(String app, HomeTileRevision reason, int revision) => _add(
    'imageRevision',
    {'reason': reason.name, 'appRevision': revision},
    app: app,
  );

  void read(String app, AppImageType type, HomeTileRead result) => _add(
    'imageRead',
    {'image': type.name.toLowerCase(), 'result': result.name},
    app: app,
  );

  void request(
    String app, {
    required int section,
    required int request,
    required (int, int) revision,
    required HomeTileReload reason,
  }) => _add('tileRequest', {
    'section': section,
    'request': request,
    'reason': reason.name,
    'cacheGeneration': revision.$1,
    'appRevision': revision.$2,
  }, app: app);

  void selection(
    String app, {
    required int section,
    required int request,
    required AppImageType type,
    required TileImageMode bannerMode,
    required TileImageMode iconMode,
    required bool retained,
    required bool sectionUsesGlobal,
    required double aspectRatio,
  }) => _add('tileSelection', {
    'section': section,
    'request': request,
    'image': type.name.toLowerCase(),
    'mode': (type == AppImageType.Icon ? iconMode : bannerMode).name,
    'bannerMode': bannerMode.name,
    'iconMode': iconMode.name,
    'retained': retained,
    'sectionUsesGlobal': sectionUsesGlobal,
    if (aspectRatio.isFinite) 'aspectRatio': aspectRatio,
  }, app: app);

  void decodeError(String app, int section, int request) =>
      _add('decodeError', {'section': section, 'request': request}, app: app);

  void focus(String app, int section) =>
      _add('tileFocus', {'section': section}, app: app);

  void _add(String event, Map<String, Object> data, {String? app}) {
    if (acceptEvent?.call() == false) return;
    int? appRef;
    if (app != null) {
      appRef = _apps[app];
      if (appRef == null) {
        if (_apps.length >= appLimit) {
          _omitted++;
          return;
        }
        appRef = _apps[app] = _apps.length + 1;
      }
    }
    if (_events.length == eventLimit) {
      _events.removeFirst();
      _omitted++;
    }
    _events.addLast(
      Map.unmodifiable({
        'elapsedMs': _elapsedMs(),
        'event': event,
        'app': ?appRef,
        ...data,
      }),
    );
  }

  Map<String, Object> snapshot() => {
    'eventLimit': eventLimit,
    'appLimit': appLimit,
    'omittedEvents': _omitted,
    'events': _events.toList(growable: false),
  };

  void clear() {
    _events.clear();
    _apps.clear();
    _omitted = 0;
    _generation++;
  }
}
