import 'package:flutter/widgets.dart';
import 'dart:async';
import '../diagnostics/startup_trace.dart';

/// A short first-screen barrier: offscreen images never delay the reveal, and
/// a hung decoder cannot hide the home indefinitely. Updates keep it visible.
class InitialAppImages extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onReady;
  const InitialAppImages({super.key, required this.child, this.onReady});

  @override
  State<InitialAppImages> createState() => _InitialAppImagesState();
}

class _InitialAppImagesState extends State<InitialAppImages> {
  final _pending = <Object, BuildContext?>{};
  bool _ready = false;
  bool _revealing = false;
  bool _layoutSettled = false, _checkScheduled = false, _timedOut = false, _focused = false;
  Timer? _timeout;

  VoidCallback _register([BuildContext? context]) {
    if (_ready) return () {};
    final ticket = Object();
    _pending[ticket] = context;
    bool completed = false;
    return () {
      if (completed) return;
      completed = true;
      _pending.remove(ticket);
      _checkReady();
    };
  }

  void _checkReady() {
    if (_ready || _checkScheduled || !mounted) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkScheduled = false;
      if (!_layoutSettled) {
        _layoutSettled = true;
        _checkReady();
        return;
      }
      if (mounted && !_ready && !_revealing && (_timedOut || !_hasVisiblePending)) {
        _revealing = true;
        if (!_focused) {
          _focused = true;
          final focus = widget.onReady?.call();
          if (focus != null) await focus.timeout(const Duration(milliseconds: 500), onTimeout: () {});
        }
        if (!_timedOut && _hasVisiblePending) {
          _revealing = false;
          _checkReady();
          return;
        }
        if (mounted) {
          _timeout?.cancel();
          _pending.clear();
          setState(() => _ready = true);
          StartupTrace.mark('homeReady', {'imageTimeout': _timedOut});
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool get _hasVisiblePending => _pending.values.any((context) {
    if (context == null) return true;
    if (!context.mounted) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    return bounds.overlaps(Offset.zero & MediaQuery.sizeOf(context));
  });

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(milliseconds: 1200), () {
      _timedOut = true;
      _checkReady();
    });
    _checkReady();
  }

  @override
  void dispose() { _timeout?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AppImagesReadiness(
        register: _register,
        child: IgnorePointer(
          ignoring: !_ready,
          child: Opacity(opacity: _ready ? 1 : 0, child: widget.child),
        ),
      );
}

class AppImagesReadiness extends InheritedWidget {
  final VoidCallback Function([BuildContext? context]) register;
  const AppImagesReadiness({super.key, required this.register, required super.child});

  @override
  bool updateShouldNotify(AppImagesReadiness oldWidget) => false;
}
