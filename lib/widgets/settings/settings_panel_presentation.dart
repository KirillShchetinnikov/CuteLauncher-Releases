import 'package:flutter/material.dart';

/// Keeps the settings navigator, scroll positions and controls alive while a
/// root-navigator editor uses the screen in place of the settings panel.
class SettingsPanelPresentation extends StatefulWidget {
  final Widget child;
  const SettingsPanelPresentation({super.key, required this.child});

  static Future<T> runHidden<T>(
    BuildContext context,
    Future<T> Function() action,
  ) {
    final state = context
        .findAncestorStateOfType<_SettingsPanelPresentationState>();
    return state == null ? action() : state._runHidden(action);
  }

  @override
  State<SettingsPanelPresentation> createState() =>
      _SettingsPanelPresentationState();
}

class _SettingsPanelPresentationState extends State<SettingsPanelPresentation> {
  int _depth = 0;
  FocusNode? _returnFocus;

  Future<T> _runHidden<T>(Future<T> Function() action) async {
    if (_depth == 0) _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _depth++);
    try {
      return await action();
    } finally {
      if (mounted) {
        setState(() => _depth--);
        if (_depth == 0) {
          final node = _returnFocus;
          _returnFocus = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _depth == 0 &&
                node?.context?.mounted == true &&
                node!.canRequestFocus) {
              node.requestFocus();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: _depth > 0,
    child: Offstage(
      offstage: _depth > 0,
      child: TickerMode(enabled: _depth == 0, child: widget.child),
    ),
  );
}
