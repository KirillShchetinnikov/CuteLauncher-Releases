import 'dart:async';
import 'dart:typed_data';

import '../diagnostics_store.dart';

import 'package:flutter/material.dart';

import 'notice_style.dart';
import 'launcher_dialog.dart';
import 'notification_popup_presentation.dart';
import 'notice_placement.dart';
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
  if (error) {
    DiagnosticsStore.instance.record(
      'dart',
      'actionNotice',
      'error',
      'operation_failed',
      context: {
        'errorText': message,
        'frames': DiagnosticsStore.safeFrames(StackTrace.current),
      },
    );
  }
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
  final bool avoidPanels;
  final Stream<Map<dynamic, dynamic>>? popupStream;
  const ActionNoticeHost({
    super.key,
    required this.child,
    this.avoidPanels = true,
    this.popupStream,
  });
  @override
  State<ActionNoticeHost> createState() => _ActionNoticeHostState();
}

class _ActionNoticeHostState extends State<ActionNoticeHost> {
  final model = _Notices();
  @override
  Widget build(BuildContext context) => NotificationPopupPresentation(
    avoidPanels: widget.avoidPanels,
    onPopup: model.addPlatform,
    popupStream: widget.popupStream,
    child: Stack(
      children: [
        widget.child,
        _NoticeStack(model: model),
      ],
    ),
  );
}

class _Notice {
  String message;
  final bool error;
  Widget? content;
  Timer? timer;
  bool closing = false;
  String? platformKey;
  _Notice(this.message, this.error, [this.content]);
}

class _Notices extends ChangeNotifier {
  bool settingsOpen = false, onRight = false;
  OverlayEntry? entry;
  final items = <_Notice>[];
  void addPlatform(Map<dynamic, dynamic> popup) {
    final key = popup['key'];
    if (key is! String) return;
    final index = items.indexWhere((notice) => notice.platformKey == key);
    final title = popup['title'] as String? ?? '';
    final label = popup['appLabel'] as String? ?? '';
    final text = popup['text'] as String? ?? '';
    final icon = popup['icon'];
    final notice = index < 0 ? _Notice('', false) : items[index];
    notice.timer?.cancel();
    notice.closing = false;
    notice.message = '$label $title $text';
    notice.content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon is Uint8List) ...[
          Image.memory(
            icon,
            width: 24,
            height: 24,
            errorBuilder: (_, _, _) => const Icon(Icons.apps),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                [label, title].where((s) => s.isNotEmpty).join(' • '),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (text.isNotEmpty) ...[const SizedBox(height: 4), Text(text)],
            ],
          ),
        ),
      ],
    );
    notice.platformKey = key;
    if (index < 0) items.add(notice);
    notice.timer = Timer(
      Duration(
        milliseconds: (popup['durationMs'] as int? ?? 5000).clamp(1, 5000),
      ),
      () => dismiss(notice),
    );
    notifyListeners();
  }

  VoidCallback add(
    String message,
    bool error,
    Duration? duration, [
    Widget? content,
  ]) {
    final notice = _Notice(message, error, content);
    items.add(notice);
    if (duration != null) {
      notice.timer = Timer(duration, () => dismiss(notice));
    }
    notifyListeners();
    return () => dismiss(notice);
  }

  void dismiss(_Notice notice) {
    if (!items.contains(notice) || notice.closing) return;
    notice.timer?.cancel();
    notice.closing = true;
    notifyListeners();
  }

  void finishDismiss(_Notice notice) {
    if (notice.closing && items.remove(notice)) notifyListeners();
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
  Widget build(BuildContext context) {
    final corner =
        NoticePlacementScope.maybeOf(context) ??
        (widget.model.settingsOpen && widget.model.onRight
            ? NoticeCorner.bottomLeft
            : NoticeCorner.bottomRight);
    return Positioned.fill(
      child: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) => IgnorePointer(
          child: ExcludeFocus(
            child: SafeArea(
              minimum: const EdgeInsets.all(24),
              child: AnimatedAlign(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: corner.alignment,
                child: SizedBox(
                  width: NoticeStyle.of(context).width,
                  child: ClipRect(
                    clipBehavior: Clip.none,
                    child: OverflowBox(
                      alignment: corner.alignment,
                      maxHeight: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final notice in widget.model.items)
                            _NoticeEntrance(
                              key: ObjectKey(notice),
                              left: corner.left,
                              closing: notice.closing,
                              onClosed: () =>
                                  widget.model.finishDismiss(notice),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: corner.top ? 0 : 8,
                                  bottom: corner.top ? 8 : 0,
                                ),
                                child: Semantics(
                                  liveRegion: true,
                                  child: NoticeSurface(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: notice.platformKey != null
                                          ? notice.content!
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  notice.error
                                                      ? Icons.error_outline
                                                      : Icons
                                                            .check_circle_outline,
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
                                                        style: NoticeStyle.of(
                                                          context,
                                                        ).textStyle,
                                                      ),
                                                ),
                                              ],
                                            ),
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
    );
  }
}

class _NoticeEntrance extends StatefulWidget {
  final Widget child;
  final bool left;
  final bool closing;
  final VoidCallback onClosed;
  const _NoticeEntrance({
    super.key,
    required this.child,
    required this.left,
    required this.closing,
    required this.onClosed,
  });
  @override
  State<_NoticeEntrance> createState() => _NoticeEntranceState();
}

class _NoticeEntranceState extends State<_NoticeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) _closed();
      });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate();
  }

  @override
  void didUpdateWidget(_NoticeEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.closing != widget.closing) _animate();
  }

  void _animate() {
    if (widget.closing) {
      if (MediaQuery.disableAnimationsOf(context) || _controller.isDismissed) {
        _closed();
      } else {
        _controller.reverse();
      }
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  void _closed() {
    if (!mounted || !widget.closing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.closing) widget.onClosed();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        MediaQuery.disableAnimationsOf(context)
            ? 0
            : (widget.left ? -1 : 1) *
                  (NoticeStyle.of(context).width + 48) *
                  (1 - Curves.easeOutCubic.transform(_controller.value)),
        0,
      ),
      child: child,
    ),
  );
}
