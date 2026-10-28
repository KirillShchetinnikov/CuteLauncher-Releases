import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Opt-in measurements of the real launcher, without writing user data.
class StartupTrace {
  static const enabled = bool.fromEnvironment('CUTE_STARTUP_PROBE');
  static final _clock = Stopwatch()..start();
  static void mark(String phase, [Map<String, Object?> details = const {}]) {
    if (!enabled) return;
    debugPrint('CUTE_STARTUP ${jsonEncode({
      'phase': phase, 'elapsedUs': _clock.elapsedMicroseconds,
      'time': DateTime.now().toUtc().toIso8601String(), ...details,
    })}');
  }
}

class StartupDiagnostics extends StatefulWidget {
  final Widget child;
  const StartupDiagnostics({super.key, required this.child});
  @override
  State<StartupDiagnostics> createState() => _StartupDiagnosticsState();
}

class _StartupDiagnosticsState extends State<StartupDiagnostics>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_key);
    WidgetsBinding.instance.addPostFrameCallback((_) => StartupTrace.mark('firstFrame'));
  }

  bool _key(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final watch = Stopwatch()..start();
    StartupTrace.mark('key', {'key': event.logicalKey.keyId});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? focused;
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
        if (element.widget.runtimeType.toString() == 'AppCard') {
          final key = element.widget.key;
          focused = key is ValueKey ? key.value.toString() : null;
          return false;
        }
        return true;
      });
      if (mounted) { StartupTrace.mark('keyFrame', {
        'key': event.logicalKey.keyId, 'latencyUs': watch.elapsedMicroseconds,
        'focus': focused ?? FocusManager.instance.primaryFocus?.debugLabel,
      }); }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    StartupTrace.mark('lifecycle', {'state': state.name});
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) StartupTrace.mark('resumeFrame');
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_key);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
