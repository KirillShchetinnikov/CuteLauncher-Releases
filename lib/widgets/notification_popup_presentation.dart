import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';
import 'notice_style.dart';

/// Shares the actual notice theme and menu placement with Android overlays.
class NotificationPopupPresentation extends StatefulWidget {
  static final settingsDepth = ValueNotifier<int>(0);
  final Widget child;
  const NotificationPopupPresentation({super.key, required this.child});

  @override
  State<NotificationPopupPresentation> createState() => _PresentationState();
}

class _PresentationState extends State<NotificationPopupPresentation>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('me.efesser.flauncher/method');
  bool _active = true;
  Map<String, Object>? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationPopupPresentation.settingsDepth.addListener(_changed);
  }

  void _changed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active && _last != null) {
      _last = {..._last!, 'left': false};
      unawaited(_send(_last!));
    }
    _changed();
  }

  Future<void> _send(Map<String, Object> payload) async {
    try {
      await _channel.invokeMethod<void>('setNotificationPopupPresentation', payload);
    } on MissingPluginException {
      // Non-Android tests do not attach the native bridge.
    } on PlatformException {
      // A detached engine must not break the app UI.
    }
  }

  @override
  void dispose() {
    NotificationPopupPresentation.settingsDepth.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = NoticeStyle.of(context);
    final payload = <String, Object>{
      'left':
          _active &&
          NotificationPopupPresentation.settingsDepth.value > 0 &&
          (context.watch<SettingsService?>()?.settingsMenuOnRight ?? false),
      'background': style.background.toARGB32(),
      'foreground': style.foreground.toARGB32(),
      'border': style.border.toARGB32(),
      'radius': style.radius,
      'width': style.width,
      'textSize': style.textSize,
    };
    if (_last == null || payload.entries.any((e) => _last![e.key] != e.value)) {
      _last = payload;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !identical(_last, payload)) return;
        await _send(payload);
      });
    }
    return widget.child;
  }
}
