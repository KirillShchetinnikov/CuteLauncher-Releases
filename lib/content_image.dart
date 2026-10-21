import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pool/pool.dart';

// Weak memoization never keeps encoded images alive. At most two large-input
// fingerprint jobs run off the UI thread; no worker stays alive after its job.
final _fingerprints = Expando<String>();
final _pending = Expando<Future<String>>();
final _fingerprintPool = Pool(2);

String _fingerprint(Uint8List bytes) => sha256.convert(bytes).toString();

/// Re-reading identical encoded bytes reuses the decoded image after encoded
/// LRU eviction. Changed bytes get a new key; paths/versions alone cannot ensure
/// freshness. Like MemoryImage, callers must not mutate the input bytes.
Future<ContentImage> contentImage(Uint8List bytes, {double scale = 1}) {
  final cached = _fingerprints[bytes];
  if (cached != null) {
    return SynchronousFuture(ContentImage._(bytes, cached, scale));
  }
  if (bytes.lengthInBytes <= 64 * 1024) {
    final fingerprint = _fingerprints[bytes] = _fingerprint(bytes);
    return SynchronousFuture(ContentImage._(bytes, fingerprint, scale));
  }
  final pending = _pending[bytes] ??= _fingerprintPool
      .withResource(() => compute(_fingerprint, bytes))
      .then((fingerprint) {
        _fingerprints[bytes] = fingerprint;
        return fingerprint;
      })
      .whenComplete(() => _pending[bytes] = null);
  return pending.then(
    (fingerprint) => ContentImage._(bytes, fingerprint, scale),
  );
}

class ContentImage extends MemoryImage {
  final String fingerprint;
  const ContentImage._(super.bytes, this.fingerprint, double scale)
    : super(scale: scale);

  @override
  bool operator ==(Object other) =>
      other is ContentImage &&
      other.fingerprint == fingerprint &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(fingerprint, scale);
}
