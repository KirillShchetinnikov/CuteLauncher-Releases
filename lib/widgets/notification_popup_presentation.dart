import 'package:flauncher/bridge_result.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_service.dart';
import 'notice_style.dart';
import 'notice_placement.dart';

/// Shares the actual notice theme and menu placement with Android overlays.
class NotificationPopupPresentation extends StatefulWidget {
  final Widget child;
  final void Function(Map<dynamic, dynamic>)? onPopup;
  final bool avoidPanels;
  final Stream<Map<dynamic, dynamic>>? popupStream;
  const NotificationPopupPresentation({
    super.key,
    required this.child,
    this.onPopup,
    this.avoidPanels = true,
    this.popupStream,
  });

  @override
  State<NotificationPopupPresentation> createState() => _PresentationState();
}

class _PresentationState extends State<NotificationPopupPresentation>
    with WidgetsBindingObserver {
  static const _channel = BridgeChannel('me.efesser.flauncher/method', preserveErrorCodes: true);
  bool _active = true;
  Map<String, Object>? _last;
  final String _host =
      '${DateTime.now().microsecondsSinceEpoch}-${UniqueKey()}';
  StreamSubscription<dynamic>? _popups;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    NoticePanels.instance.addListener(_changed);
    if (widget.onPopup != null &&
        (widget.popupStream != null || Platform.isAndroid)) {
      _popups =
          (widget.popupStream ??
                  const EventChannel(
                    'me.efesser.flauncher/event_notification_popup',
                  ).receiveBroadcastStream(_host))
              .listen((event) {
                if (mounted && _active && event is Map) {
                  widget.onPopup?.call(event);
                }
              }, onError: (Object _) {});
    }
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
      _last = {..._last!, 'active': false, 'left': _last!['preferredLeft']!};
      unawaited(_send(_last!));
    }
    _changed();
  }

  Future<void> _send(Map<String, Object> payload) async {
    try {
      await _channel.invokeMethod<void>(
        'setNotificationPopupPresentation',
        payload,
      );
    } on MissingPluginException {
      // Non-Android tests do not attach the native bridge.
    } on PlatformException {
      // A detached engine must not break the app UI.
    }
  }

  @override
  void dispose() {
    NoticePanels.instance.removeListener(_changed);
    _popups?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = NoticeStyle.of(context);
    final preferred = NoticeCorner.parse(
      context.watch<AppearanceService?>()?.appearance.values['noticeCorner'],
    );
    final corner = _active && widget.avoidPanels
        ? NoticePanels.instance.resolve(preferred)
        : preferred;
    final payload = <String, Object>{
      'host': _host,
      'active': _active && widget.onPopup != null,
      'avoidPanels': widget.avoidPanels,
      'left': corner.left,
      'preferredLeft': preferred.left,
      'top': preferred.top,
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
    return NoticePlacementScope(corner: corner, child: widget.child);
  }
}

class NoticePlacementScope extends InheritedWidget {
  final NoticeCorner corner;
  const NoticePlacementScope({
    super.key,
    required this.corner,
    required super.child,
  });
  static NoticeCorner? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NoticePlacementScope>()
      ?.corner;
  @override
  bool updateShouldNotify(NoticePlacementScope oldWidget) =>
      corner != oldWidget.corner;
}
