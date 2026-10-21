import 'package:flutter/painting.dart';

/// Changing file bytes must also change the key used by ResizeImage's cache.
class VersionedFileImage extends FileImage {
  final int revision;
  const VersionedFileImage(super.file, this.revision);
  @override
  bool operator ==(Object other) => other is VersionedFileImage &&
      other.file.path == file.path && other.scale == scale && other.revision == revision;
  @override
  int get hashCode => Object.hash(file.path, scale, revision);
}
