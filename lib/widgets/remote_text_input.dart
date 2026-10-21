import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keep TV remote navigation with the IME until the keyboard is dismissed.
class RemoteTextInput extends StatefulWidget {
  final Widget child;
  final bool traverseWhenHidden;
  final Stream<bool>? imeVisibility;
  final ValueChanged<bool>? onEditorFocusChanged;
  const RemoteTextInput({
    super.key,
    required this.child,
    this.traverseWhenHidden = true,
    this.imeVisibility,
    this.onEditorFocusChanged,
  });

  @override
  State<RemoteTextInput> createState() => _RemoteTextInputState();
}

class _RemoteTextInputState extends State<RemoteTextInput> {
  static const _editorChannel = MethodChannel('cutelauncher/tv_ime_editor');
  static int _nextEditor = 0;
  final int _editor = ++_nextEditor;
  bool _focused = false;
  // All editors share one native listener, including forms with several fields.
  static final Stream<dynamic> _androidImeVisibility = const EventChannel(
    'cutelauncher/ime_visibility',
  ).receiveBroadcastStream();
  StreamSubscription<dynamic>? _subscription;
  bool _imeVisible = false;

  @override
  void initState() {
    super.initState();
    final events =
        widget.imeVisibility ??
        (Platform.isAndroid
            ? _androidImeVisibility
            : const Stream<bool>.empty());
    _subscription = events.listen((value) {
      if (mounted && value is bool && value != _imeVisible) {
        setState(() => _imeVisible = value);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    if (_focused) _editorFocusChanged(false);
    _subscription?.cancel();
    super.dispose();
  }

  void _editorFocusChanged(bool focused) {
    _focused = focused;
    if (widget.onEditorFocusChanged != null) {
      widget.onEditorFocusChanged!(focused);
    } else if (Platform.isAndroid) {
      unawaited(
        _editorChannel
            .invokeMethod<void>('focus', {
              'editor': _editor,
              'focused': focused,
            })
            .catchError((Object _) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        _imeVisible || MediaQuery.viewInsetsOf(context).bottom > 0;
    const platformInput = DoNothingAndStopPropagationIntent();
    return Shortcuts(
      shortcuts: {
        if (keyboardOpen || widget.traverseWhenHidden) ...{
          const SingleActivator(LogicalKeyboardKey.arrowUp): keyboardOpen
              ? platformInput
              : const PreviousFocusIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowDown): keyboardOpen
              ? platformInput
              : const NextFocusIntent(),
        },
        if (keyboardOpen) ...{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): platformInput,
          const SingleActivator(LogicalKeyboardKey.arrowRight): platformInput,
        },
        for (final key in [
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
        ])
          SingleActivator(key): keyboardOpen
              ? platformInput
              : const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              FocusManager.instance.primaryFocus?.context
                  ?.findAncestorStateOfType<EditableTextState>()
                  ?.requestKeyboard();
              return null;
            },
          ),
        },
        child: Focus(
          canRequestFocus: false,
          onFocusChange: _editorFocusChanged,
          child: widget.child,
        ),
      ),
    );
  }
}
