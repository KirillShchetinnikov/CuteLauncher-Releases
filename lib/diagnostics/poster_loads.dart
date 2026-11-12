import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../image_limits.dart';

enum PosterSource { appChannels, watchNext }

enum PosterStage {
  queue,
  connection,
  headers,
  body,
  validation,
  platform,
  decode,
}

enum PosterOutcome { loaded, failed, cachedFallback, discarded }

/// A bounded, passive trace. No URLs, content IDs, exception text or network I/O.
class PosterLoads {
  static const activeLimit = 32, recentLimit = 40, failureLimit = 40;
  final int Function() _now;
  late Hmac _hash = _newHash();
  int _generation = 0, _sequence = 0, _omittedActive = 0;
  final _active = <int, PosterLoad>{};
  final _recent = <Map<String, Object>>[];
  final _failures = <Map<String, Object>>[];
  final _events = <Map<String, Object>>[];
  final _counts = <String, int>{};
  final _lifecycle = <PosterSource, String>{};
  Map<String, Object> _network = {'status': 'unknown'};

  PosterLoads(this._now);

  Hmac _newHash() {
    final random = Random.secure();
    return Hmac(sha256, List.generate(32, (_) => random.nextInt(256)));
  }

  String _id(String value) =>
      _hash.convert(utf8.encode(value)).toString().substring(0, 16);

  void count(PosterSource source, String event) {
    if (!const {
      'started',
      'loaded',
      'failed',
      'cachedFallback',
      'discarded',
      'cacheHit',
      'deduplicated',
    }.contains(event)) {
      return;
    }
    final key = '${source.name}.$event';
    _counts[key] = (_counts[key] ?? 0) + 1;
  }

  void lifecycle(PosterSource source, String state) {
    if (!const {
          'resumed',
          'inactive',
          'hidden',
          'paused',
          'detached',
          'disposed',
        }.contains(state) ||
        _lifecycle[source] == state) {
      return;
    }
    _lifecycle[source] = state;
    _event({'source': source.name, 'state': state});
  }

  void network({
    required String transport,
    required bool internetAccess,
    required bool vpnActive,
  }) {
    final next = <String, Object>{
      'status': 'observed',
      'transport':
          const {
            'Wifi',
            'Wired',
            'Cellular',
            'Vpn',
            'Unknown',
          }.contains(transport)
          ? transport
          : 'Unknown',
      'internetAccess': internetAccess,
      'vpnActive': vpnActive,
    };
    if (jsonEncode(next) != jsonEncode({..._network}..remove('elapsedMs'))) {
      _event({'network': next});
    }
    _network = {...next, 'elapsedMs': _now()};
  }

  void _event(Map<String, Object> event) {
    _events.add({'elapsedMs': _now(), ...event});
    if (_events.length > 16) _events.removeAt(0);
  }

  PosterLoad start(
    PosterSource source,
    String address, {
    String? packageName,
    bool thumbnail = false,
    bool cached = false,
  }) {
    // Bound parsing/hash work too; oversized addresses are never copied.
    Uri? uri;
    String? endpoint;
    try {
      uri = address.length <= 8192 ? Uri.tryParse(address) : null;
      if (uri != null) endpoint = '${uri.scheme}://${uri.host}:${uri.port}';
    } on FormatException {
      uri = null;
    }
    final scheme = uri?.scheme ?? '';
    final data = <String, Object>{
      'id': ++_sequence,
      'source': source.name,
      'variant': thumbnail ? 'thumbnail' : 'primary',
      'cachedAtStart': cached,
      'scheme':
          const {
            'http',
            'https',
            'content',
            'android.resource',
            'file',
          }.contains(scheme)
          ? scheme
          : 'other',
      'networkAtStart': Map<String, Object>.from(_network),
      'lifecycleAtStart': _lifecycle[source] ?? 'unknown',
      'sourceActiveAtStart': _active.values
          .where((p) => p.source == source && p._stage != PosterStage.queue)
          .length,
      'sourceQueuedAtStart': _active.values
          .where((p) => p.source == source && p._stage == PosterStage.queue)
          .length,
    };
    if (packageName != null &&
        packageName.length <= 255 &&
        RegExp(r'^[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+$')
            .hasMatch(packageName)) {
      data['packageName'] = packageName;
    }
    if (uri != null) {
      data['imageId'] = _id(address);
      data['endpointId'] = _id(endpoint!);
      data['endpointGroup'] =
          uri.host == 'ytimg.com' || uri.host.endsWith('.ytimg.com')
          ? 'youtubeImages'
          : 'other';
    }
    final load = PosterLoad._(this, source, _generation, data);
    _active[load.id] = load;
    if (_active.length > activeLimit) {
      _active.remove(_active.keys.first);
      _omittedActive++;
    }
    count(source, 'started');
    return load;
  }

  void decodeFailed(
    PosterSource source,
    String address,
    String thumbnail,
    String packageName,
  ) {
    final load = start(source, address, packageName: packageName);
    // The widget may display either candidate (or retained bytes after eviction).
    load._data['variant'] = 'displayed';
    if (thumbnail.isNotEmpty && thumbnail.length <= 8192) {
      load._data['alternateImageId'] = _id(thumbnail);
    }
    load.stage(PosterStage.decode);
    // A widget decode failure is not proof that the encoded bytes are corrupt.
    load._data['reason'] = 'decode';
    load.finish(PosterOutcome.failed);
  }

  void clear() {
    ++_generation;
    _active.clear();
    _recent.clear();
    _failures.clear();
    _events.clear();
    _counts.clear();
    _lifecycle.clear();
    _network = {'status': 'unknown'};
    _hash = _newHash();
    _sequence = 0;
    _omittedActive = 0;
  }

  Map<String, Object> snapshot() => Map<String, Object>.from(
    jsonDecode(
      jsonEncode({
        'scope': 'current_session',
        'limits': {
          'active': activeLimit,
          'recent': recentLimit,
          'failures': failureLimit,
        },
        'loaderConcurrency': 2,
        'maxConnectionsPerHost': 2,
        'omittedActive': _omittedActive,
        'counts': _counts,
        'network': _network,
        'events': _events,
        'active': _active.values.map((load) => load._snapshot()).toList(),
        'recent': _recent,
        'failures': _failures,
      }),
    ),
  );
}

class PosterLoad {
  final PosterLoads _owner;
  final PosterSource source;
  final int _generation;
  final Map<String, Object> _data;
  final Map<String, int> _durations = {};
  late final int _started = _owner._now();
  late int _stageStarted = _started;
  PosterStage _stage = PosterStage.queue;
  bool _finished = false;
  int receivedBytes = 0;
  int get id => _data['id'] as int;

  PosterLoad._(this._owner, this.source, this._generation, this._data) {
    // Start the clock while queued, not on the first snapshot.
    _stageStarted = _started;
  }

  void stage(PosterStage stage) {
    _durations[_stage.name] =
        (_durations[_stage.name] ?? 0) + (_owner._now() - _stageStarted);
    _stage = stage;
    _stageStarted = _owner._now();
  }

  void response(HttpClientResponse response) {
    _data['httpStatus'] = response.statusCode;
    _data['redirectCount'] = response.redirects.length;
    if (response.contentLength >= 0) {
      _data['expectedBytes'] = response.contentLength;
    }
    String? mime;
    try {
      mime = response.headers.contentType?.mimeType;
    } on FormatException {
      // A malformed diagnostic header must not change image loading behavior.
    }
    _data['contentType'] =
        const {
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/gif',
          'image/avif',
          'text/html',
          'text/plain',
          'application/json',
          'application/octet-stream',
        }.contains(mime)
        ? mime!
        : 'other';
  }

  void error(Object error) {
    final status = _data['httpStatus'];
    _data['reason'] = status is int && status != HttpStatus.ok
        ? 'http'
        : switch (error) {
            TimeoutException() => 'timeout',
            TlsException() => 'tls',
            SocketException() =>
              error.message.toLowerCase().contains('failed host lookup')
                  ? 'dns'
                  : 'connection',
            HttpException() => 'connection',
            ImageInputException() => switch (error.reason) {
              ImageInputFailure.bytes => 'tooLarge',
              ImageInputFailure.dimensions => 'dimensions',
              ImageInputFailure.invalid => 'invalidImage',
            },
            PlatformException() => 'platform',
            FormatException() => 'invalidResponse',
            _ => 'unknown',
          };
    if (error is TimeoutException && error.duration != null) {
      _data['timeoutMs'] = error.duration!.inMilliseconds;
    }
    if (error is SocketException && error.osError != null) {
      _data['osErrorCode'] = error.osError!.errorCode;
    }
  }

  Map<String, Object> _snapshot() => {
    ..._data,
    'startedElapsedMs': _started,
    'durationMs': _owner._now() - _started,
    'stage': _stage.name,
    'stageDurationsMs': {
      ..._durations,
      _stage.name:
          (_durations[_stage.name] ?? 0) + _owner._now() - _stageStarted,
    },
    'receivedBytes': receivedBytes,
  };

  void finish(PosterOutcome outcome) {
    if (_finished || _generation != _owner._generation) return;
    _finished = true;
    _owner._active.remove(id);
    if ((outcome == PosterOutcome.failed ||
            outcome == PosterOutcome.cachedFallback) &&
        !_data.containsKey('reason')) {
      _data['reason'] = 'noImage';
    }
    final row = {
      ..._snapshot(),
      'outcome': outcome.name,
      'networkAtEnd': Map<String, Object>.from(_owner._network),
      'lifecycleAtEnd': _owner._lifecycle[source] ?? 'unknown',
    };
    _owner._recent.add(row);
    if (_owner._recent.length > PosterLoads.recentLimit) {
      _owner._recent.removeAt(0);
    }
    if (_data.containsKey('reason')) {
      _owner._failures.add(row);
      if (_owner._failures.length > PosterLoads.failureLimit) {
        _owner._failures.removeAt(0);
      }
    }
    _owner.count(source, outcome.name);
  }
}
