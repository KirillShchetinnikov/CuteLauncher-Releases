import 'package:flutter/foundation.dart';

/// Shared lifetime guard for services with callbacks that cannot be cancelled.
mixin ServiceLifecycle on ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
