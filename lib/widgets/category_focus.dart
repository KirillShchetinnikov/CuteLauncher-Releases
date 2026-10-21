import 'package:flutter/widgets.dart';

import '../models/category.dart';

/// Owns the row scroll position and references only mounted cards' focus nodes.
class CategoryFocusController {
  final scrollController = ScrollController();
  final _nodes = <String, FocusNode>{};
  bool _disposed = false;
  bool rememberLast = false;
  final selected = ValueNotifier<String?>(null);
  bool Function(String, AxisDirection)? navigate;
  Future<bool> Function(String)? materialize;
  void Function()? reveal;
  void Function(AxisDirection, double)? leave;
  Future<bool> Function(AxisDirection, double)? enter;
  bool get hasItems => _packages.isNotEmpty;
  bool get hasFocus => _nodes.values.any((node) => node.hasFocus);
  String? get lastPackage => _lastPackage;
  Future<bool> focusPackage(String package) => _materialize(package);
  Future<bool> restoreAfterEdit(String package, int oldIndex) {
    if (_disposed || _packages.isEmpty) return Future.value(false);
    return _materialize(_packages.contains(package) ? package
        : _packages[oldIndex.clamp(0, _packages.length - 1)]);
  }
  bool focusMounted(String package) {
    final node = _nodes[package];
    if (_disposed || node == null || !node.canRequestFocus) return false;
    node.requestFocus(); return true;
  }
  VoidCallback? onSelected;
  List<String> _packages = [];
  String? _lastPackage;
  double _itemExtent = 0;
  double gap = 0;
  CategoryFocusController? parent;
  CategoryFocusController get root => parent?.root ?? this;
  final Map<String, CategoryFocusController> scrollDelegates = {};
  int _request = 0;

  void configure(Iterable<String> packages) {
    _packages = packages.toList();
  }

  void record(String package, FocusNode node) {
    if (!_packages.contains(package)) return;
    _lastPackage = package;
    selected.value = package;
    onSelected?.call();
    if (node.context != null) _itemExtent = node.rect.width + gap;
    parent?.record(package, node);
  }

  String? get _entryPackage => rememberLast && _packages.contains(_lastPackage)
      ? _lastPackage
      : _packages.firstOrNull;

  /// Enter a different row, restoring a package identity rather than its index.
  void requestEntry(FocusNode from, FocusNode fallback) {
    final fromSection = from.context
        ?.getInheritedWidgetOfExactType<CategoryFocus>()?.controller;
    // The top bar temporarily borrows focus; resume the same app by identity.
    if (enter != null && fromSection == null && _packages.contains(_lastPackage)) {
      final request = ++_request;
      _materialize(_lastPackage, isCurrent: () =>
          request == _request && FocusManager.instance.primaryFocus == from);
      return;
    }
    if (enter != null) {
      enter!(fallback.rect.center.dy > from.rect.center.dy ? AxisDirection.down : AxisDirection.up, from.rect.center.dx);
      return;
    }
    if (!rememberLast && scrollDelegates.isNotEmpty) { fallback.requestFocus(); return; }
    final package = _entryPackage;
    final node = _nodes[package];
    final request = ++_request;
    if (node != null && node.context != null && node.canRequestFocus) {
      node.requestFocus();
      return;
    }
    _materialize(
      package,
      isCurrent: () =>
          request == _request && FocusManager.instance.primaryFocus == from,
    ).then((focused) {
      if (!focused &&
          !_disposed &&
          request == _request &&
          FocusManager.instance.primaryFocus == from &&
          fallback.context != null) {
        fallback.requestFocus();
      }
    });
  }

  void register(String package, FocusNode node) {
    _nodes[package] = node;
    parent?.register(package, node);
  }
  void unregister(String package, FocusNode node) {
    if (identical(_nodes[package], node)) _nodes.remove(package);
    parent?.unregister(package, node);
  }

  Future<bool> focusCategory(
    Category category, {
    bool Function()? isCurrent,
  }) async {
    configure(
      category.applications.map((app) => app.packageName),
    );
    final request = ++_request;
    return _materialize(
      _entryPackage,
      isCurrent: () => request == _request && isCurrent?.call() != false,
    );
  }

  Future<bool> focusEntry({bool Function()? isCurrent}) {
    final request = ++_request;
    return _materialize(_entryPackage,
        isCurrent: () => request == _request && isCurrent?.call() != false);
  }

  Future<bool> _materialize(
    String? package, {
    bool Function()? isCurrent,
  }) async {
    if (_disposed) return false;
    if (materialize != null && package != null) {
      if (isCurrent?.call() == false) return false;
      return materialize!(package);
    }
    final delegate = scrollDelegates[package];
    if (delegate != null) return delegate._materialize(package, isCurrent: isCurrent);
    if (scrollController.hasClients) {
      final index = _packages.indexOf(package ?? '');
      final offset = index > 0 ? index * _itemExtent : 0.0;
      scrollController.jumpTo(
        offset.clamp(0.0, scrollController.position.maxScrollExtent),
      );
    }
    // Scrolling a lazy row materializes its first card in the next frame.
    WidgetsBinding.instance.ensureVisualUpdate();
    await WidgetsBinding.instance.endOfFrame;
    if (_disposed || isCurrent?.call() == false) return false;
    final node = _nodes[package];
    if (node == null || !node.canRequestFocus) return false;
    node.requestFocus();
    return true;
  }

  void dispose() {
    ++_request;
    _disposed = true;
    _nodes.clear();
    selected.dispose();
    scrollController.dispose();
  }
}

class CategoryFocus extends InheritedWidget {
  final CategoryFocusController controller;
  const CategoryFocus({
    super.key,
    required this.controller,
    required super.child,
  });
  static CategoryFocusController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CategoryFocus>()?.controller;
  @override
  bool updateShouldNotify(CategoryFocus oldWidget) =>
      controller != oldWidget.controller;
}
