import 'dart:typed_data';

/// LRU of encoded image bytes. Live widgets/decoded images have separate lifetimes.
class ImageByteCache {
  final int maximumEntries;
  final void Function(String, Uint8List)? onEvict;
  int _maximumBytes;
  int _bytes = 0;
  final _entries = <String, Uint8List>{};
  int _hits = 0;
  int _misses = 0;
  int _writes = 0;
  Map<String, int> get activity => {'hits': _hits, 'misses': _misses, 'writes': _writes};

  ImageByteCache(
      {required this._maximumBytes, this.maximumEntries = 128, this.onEvict});
  int get byteCount => _bytes;
  int get length => _entries.length;
  int get maximumBytes => _maximumBytes;
  set maximumBytes(int value) {
    _maximumBytes = value;
    _trim();
  }

  Uint8List? operator [](String key) {
    final value = _entries.remove(key);
    if (const bool.fromEnvironment('CUTE_PERFORMANCE_PROBE')) {
      if (value == null) { _misses++; } else { _hits++; }
    }
    if (value != null) _entries[key] = value;
    return value;
  }

  bool containsKey(String key) {
    final present = _entries.containsKey(key);
    if (const bool.fromEnvironment('CUTE_PERFORMANCE_PROBE') && !present) _misses++;
    return present;
  }
  void operator []=(String key, Uint8List value) {
    if (const bool.fromEnvironment('CUTE_PERFORMANCE_PROBE')) _writes++;
    remove(key);
    if (value.lengthInBytes > _maximumBytes || maximumEntries <= 0) return;
    // A short view must not keep a larger codec/input buffer alive.
    final stored = value.buffer.lengthInBytes == value.lengthInBytes
        ? value
        : Uint8List.fromList(value);
    _entries[key] = stored;
    _bytes += stored.lengthInBytes;
    _trim();
  }

  void remove(String key) {
    final value = _entries.remove(key);
    if (value == null) return;
    _bytes -= value.lengthInBytes;
    onEvict?.call(key, value);
  }

  void clear() {
    for (final key in _entries.keys.toList()) {
      remove(key);
    }
  }

  void _trim() {
    while (_entries.isNotEmpty &&
        (_bytes > _maximumBytes || _entries.length > maximumEntries)) {
      remove(_entries.keys.first);
    }
  }
}
