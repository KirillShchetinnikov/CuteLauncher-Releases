import 'package:flutter/widgets.dart';

/// Mounts the home screen immediately, but reveals it after its images decode.
/// This barrier is used once; subsequent updates keep the home screen visible.
class InitialAppImages extends StatefulWidget {
  final Widget child;
  const InitialAppImages({super.key, required this.child});

  @override
  State<InitialAppImages> createState() => _InitialAppImagesState();
}

class _InitialAppImagesState extends State<InitialAppImages> {
  int _pending = 0;
  bool _ready = false;

  VoidCallback _register() {
    if (_ready) return () {};
    _pending++;
    bool completed = false;
    return () {
      if (completed) return;
      completed = true;
      _pending--;
      _checkReady();
    };
  }

  void _checkReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_ready && _pending == 0) {
        setState(() => _ready = true);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void initState() {
    super.initState();
    _checkReady();
  }

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
  final VoidCallback Function() register;
  const AppImagesReadiness({super.key, required this.register, required super.child});

  @override
  bool updateShouldNotify(AppImagesReadiness oldWidget) => false;
}
