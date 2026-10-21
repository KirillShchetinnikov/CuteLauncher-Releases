import 'dart:async';

import 'package:flutter/material.dart';

import 'notice_style.dart';
import 'launcher_dialog.dart';
import 'notification_popup_presentation.dart';
import 'settings/settings_menu_layout.dart';

/// Results of explicit actions, above routes without taking remote focus.
VoidCallback showActionNotice(
  BuildContext context,
  String message, {
  bool error = false,
  Duration duration = const Duration(seconds: 5),
  Widget? content,
  bool persistent = false,
  bool? settingsOpen,
  bool? onRight,
}) {
  if (!context.mounted) return () {};
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  if (lifecycle == AppLifecycleState.paused ||
      lifecycle == AppLifecycleState.detached) {
    return () {};
  }
  final host = context.findAncestorStateOfType<_ActionNoticeHostState>();
  final menu = SettingsMenuLayout.maybeOf(context);
  final dialog = context
      .dependOnInheritedWidgetOfExactType<LauncherDialogArea>();
  settingsOpen ??= menu != null || (dialog?.settingsOpen ?? false);
  onRight ??= menu?.onRight ?? dialog?.onRight ?? false;
  if (host != null) {
    host.model.settingsOpen = settingsOpen;
    host.model.onRight = onRight;
    return host.model.add(
      message,
      error,
      persistent ? null : duration,
      content,
    );
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return () {};
  var notices = _overlays[overlay];
  if (notices == null) {
    notices = _Notices();
    _overlays[overlay] = notices;
    final model = notices;
    model.entry = OverlayEntry(
      maintainState: true,
      builder: (_) => _NoticeStack(model: model),
    );
    overlay.insert(model.entry!);
  }
  notices.settingsOpen = settingsOpen;
  notices.onRight = onRight;
  return notices.add(message, error, persistent ? null : duration, content);
}

final _overlays = Expando<_Notices>();

/// Put above the Navigator so notifications survive route and dialog changes.
class ActionNoticeHost extends StatefulWidget {
  final Widget child;
  const ActionNoticeHost({super.key, required this.child});
  @override
  State<ActionNoticeHost> createState() => _ActionNoticeHostState();
}

class _ActionNoticeHostState extends State<ActionNoticeHost> {
  final model = _Notices();
  @override
  Widget build(BuildContext context) => NotificationPopupPresentation(
    child: Stack(
      children: [
        widget.child,
        _NoticeStack(model: model),
      ],
    ),
  );
}

class _Notice {
  final String message;
  final bool error;
  final Widget? content;
  Timer? timer;
  _Notice(this.message, this.error, [this.content]);
}

class _Notices extends ChangeNotifier {
  bool settingsOpen = false, onRight = false;
  OverlayEntry? entry;
  final items = <_Notice>[];
  VoidCallback add(
    String message,
    bool error,
    Duration? duration, [
    Widget? content,
  ]) {
    final notice = _Notice(message, error, content);
    items.add(notice);
    if (duration != null) {
      notice.timer = Timer(duration, () {
        items.remove(notice);
        notifyListeners();
      });
    }
    notifyListeners();
    return () {
      notice.timer?.cancel();
      if (items.remove(notice)) notifyListeners();
    };
  }

  void clear({bool transientOnly = false}) {
    final removed = items
        .where((notice) => !transientOnly || notice.timer != null)
        .toList();
    for (final notice in removed) {
      notice.timer?.cancel();
    }
    items.removeWhere(removed.contains);
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

class _NoticeStack extends StatefulWidget {
  final _Notices model;
  const _NoticeStack({required this.model});
  @override
  State<_NoticeStack> createState() => _NoticeStackState();
}

class _NoticeStackState extends State<_NoticeStack>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.model.clear(transientOnly: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) => LauncherDialogArea(
        settingsOpen: widget.model.settingsOpen,
        onRight: widget.model.onRight,
        child: IgnorePointer(
          child: ExcludeFocus(
            child: SafeArea(
              minimum: const EdgeInsets.all(24),
              child: Align(
                alignment: widget.model.settingsOpen && widget.model.onRight
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                child: SizedBox(
                  width: NoticeStyle.of(context).width,
                  child: ClipRect(
                    child: ListenableBuilder(
                      listenable: widget.model,
                      builder: (context, _) => OverflowBox(
                        alignment:
                            widget.model.settingsOpen && widget.model.onRight
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight,
                        maxHeight: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final notice in widget.model.items)
                              Padding(
                                key: ObjectKey(notice),
                                padding: const EdgeInsets.only(top: 8),
                                child: Semantics(
                                  liveRegion: true,
                                  child: NoticeSurface(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            notice.error
                                                ? Icons.error_outline
                                                : Icons.check_circle_outline,
                                            color: notice.error
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child:
                                                notice.content ??
                                                Text(
                                                  notice.message,
                                                  style: NoticeStyle.of(context).textStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
