import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'image_limits.dart';

/// A private, disposable cache of source images. The header records freshness;
/// the file modification time records recency.
class PosterDiskCache {
  PosterDiskCache(this._directory);

  static const _headerBytes = 8;
  static const _lifetime = Duration(days: 7);
  static final _imageName = RegExp(r'^[a-f0-9]{64}$');
  final Future<Directory> Function() _directory;
  // Insertion order is LRU order, including accesses in the same clock tick.
  final _entries = <String, int>{};
  Future<void> _pending = Future.value();
  Directory? _root;
  int _maximumBytes = 32 * 1024 * 1024;
  int _bytes = 0;

  set maximumBytes(int value) {
    if (value == _maximumBytes) return;
    _maximumBytes = value;
    unawaited(_run<void>((dir) => _trim(dir)));
  }

  Future<({int bytes, int entries})?> stats() =>
      _run((_) async => (bytes: _bytes, entries: _entries.length));

  Future<({Uint8List bytes, bool fresh})?> read(
    String address, {
    DateTime? freshAfter,
  }) => _run((dir) async {
    final key = _key(address);
    if (!_entries.containsKey(key)) return null;
    final file = _file(dir, key);
    final length = await file.length();
    if (length <= _headerBytes || length > maximumImageInputBytes + _headerBytes) {
      await _remove(dir, key);
      return null;
    }
    final source = await file.open();
    late final Uint8List data;
    try {
      data = await source.read(length);
    } finally {
      await source.close();
    }
    if (data.length != length) {
      await _remove(dir, key);
      return null;
    }
    final savedMs = ByteData.sublistView(data).getInt64(0);
    final now = DateTime.now();
    if (savedMs < now.subtract(_lifetime).millisecondsSinceEpoch ||
        savedMs > now.millisecondsSinceEpoch) {
      await _remove(dir, key);
      return null;
    }
    final bytes = Uint8List.sublistView(data, _headerBytes);
    try {
      await validateImageBytes(bytes);
    } on ImageInputException {
      await _remove(dir, key);
      return null;
    }
    await file.setLastModified(now);
    _entries.remove(key);
    _entries[key] = length;
    return (
      bytes: bytes,
      fresh: freshAfter == null || savedMs >= freshAfter.millisecondsSinceEpoch,
    );
  });

  Future<void> write(
    String address,
    Uint8List data, {
    required DateTime fetchedAt,
  }) async {
    await _run<void>((dir) async {
      final length = data.lengthInBytes + _headerBytes;
      if (data.isEmpty || data.lengthInBytes > maximumImageInputBytes ||
          length > _maximumBytes) {
        return;
      }
      final key = _key(address);
      final file = _file(dir, key);
      final header = ByteData(_headerBytes)
        ..setInt64(0, fetchedAt.millisecondsSinceEpoch);
      final temporary = _file(dir, '$key.tmp');
      try {
        final output = await temporary.open(mode: FileMode.write);
        try {
          await output.writeFrom(header.buffer.asUint8List());
          await output.writeFrom(data);
        } finally {
          await output.close();
        }
        await temporary.rename(file.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      _bytes += length - (_entries.remove(key) ?? 0);
      _entries[key] = length;
      await _trim(dir);
    });
  }

  int _generation = 0;
  int get generation => _generation;

  Future<int?> clear() {
    ++_generation;
    return _run((dir) async {
      final before = _bytes;
      for (final key in _entries.keys.toList()) {
        await _remove(dir, key);
      }
      return before - _bytes;
    });
  }

  Future<void> remove(String address) async {
    await _run<void>((dir) => _remove(dir, _key(address)));
  }

  String _key(String address) => sha256.convert(utf8.encode(address)).toString();
  File _file(Directory dir, String name) =>
      File('${dir.path}${Platform.pathSeparator}$name');

  Future<Directory> _open() async {
    final dir = await _directory();
    await dir.create(recursive: true);
    _entries.clear();
    _bytes = 0;
    final cutoff = DateTime.now().subtract(_lifetime);
    final restored = <({String key, int bytes, DateTime used})>[];
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File) continue;
      final name = file.uri.pathSegments.last;
      if (!_imageName.hasMatch(name)) {
        if (name.endsWith('.tmp')) await file.delete();
        continue;
      }
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) continue;
      if (stat.modified.isBefore(cutoff)) {
        await file.delete();
        continue;
      }
      restored.add((key: name, bytes: stat.size, used: stat.modified));
      _bytes += stat.size;
    }
    restored.sort((a, b) => a.used.compareTo(b.used));
    for (final entry in restored) {
      _entries[entry.key] = entry.bytes;
    }
    await _trim(dir);
    return dir;
  }

  Future<T?> _run<T>(Future<T?> Function(Directory) operation) {
    final next = _pending.then((_) async {
      try {
        return await operation(_root ??= await _open());
      } on Exception {
        // Cache-directory lookup and file I/O are optional for showing a poster.
        _root = null;
        return null;
      }
    });
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _trim(Directory dir) async {
    while (_bytes > _maximumBytes && _entries.isNotEmpty) {
      await _remove(dir, _entries.keys.first);
    }
  }

  Future<void> _remove(Directory dir, String key) async {
    final file = _file(dir, key);
    if (await file.exists()) await file.delete();
    _bytes -= _entries.remove(key) ?? 0;
  }
}
