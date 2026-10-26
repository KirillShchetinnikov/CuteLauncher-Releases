import '../menu_header.dart';
import '../notice_style.dart';
import '../menu_header_action.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../../providers/notifications_service.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../side_panel_dialog.dart';
import 'focusable_settings_tile.dart';
import 'notifications_settings_page.dart';
import 'settings_panel.dart';
import 'settings_panel_style.dart';

class NotificationsPanel extends StatefulWidget {
  final bool? isRightSide;
  final double topInset;
  final Rect? anchor;
  const NotificationsPanel({
    super.key,
    this.isRightSide,
    this.topInset = 0,
    this.anchor,
  });
  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final _nodes = <String, FocusNode>{};
  final _hideNode = FocusNode();
  final _settingsNode = FocusNode();
  String? _focusedKey;
  List<String> _keys = [];
  bool _modalOpen = false;
  bool _busy = false;
  bool _settingsOpen = false;
  int _restoreGeneration = 0;
  List<String> _neighbors(String? key) {
    final index = _keys.indexOf(key ?? '');
    if (index < 0) return List.of(_keys);
    return [..._keys.skip(index + 1), ..._keys.take(index).toList().reversed];
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _hideNode.dispose();
    _settingsNode.dispose();
    super.dispose();
  }

  void _restore(String? key, [int index = 0, List<String>? neighbors]) {
    final generation = ++_restoreGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _modalOpen || generation != _restoreGeneration) return;
      final items = context.read<NotificationsService>().notifications;
      final next = neighbors?.firstWhereOrNull(
        (key) => items.any((n) => n.key == key),
      );
      final id = items.any((n) => n.key == key)
          ? key
          : next ??
                (items.isEmpty
                    ? null
                    : items[index.clamp(0, items.length - 1)].key);
      final node = id == null ? _hideNode : _nodes[id];
      if (node?.context != null) {
        node!.requestFocus();
        Scrollable.ensureVisible(
          node.context!,
          alignment: .5,
          duration: const Duration(milliseconds: 100),
        );
      } else {
        _hideNode.requestFocus();
      }
    });
  }

  Future<void> _change(NotificationItem item, bool block) async {
    if (_busy) return;
    if (!block && !item.isClearable) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.persistentNotificationCannotDelete,
      );
      return;
    }
    final neighbors = _neighbors(item.key);
    _busy = true;
    final index = _keys.indexOf(item.key);
    try {
      final service = context.read<NotificationsService>();
      if (block) {
        await service.blockPackage(item.packageName);
      } else if (item.isClearable) {
        await service.dismiss(item.key);
      }
    } finally {
      _busy = false;
      if (mounted) _restore(item.key, index < 0 ? 0 : index, neighbors);
    }
  }

  Future<void> _options(NotificationItem item, String name) async {
    if (_modalOpen) return;
    _modalOpen = true;
    final index = _keys.indexOf(item.key);
    final neighbors = _neighbors(item.key);
    final apps = context.read<AppsService>();
    final app = apps.applications.firstWhereOrNull(
      (a) => a.packageName == item.packageName,
    );
    final service = context.read<NotificationsService>();
    final canOpen = item.hasContentIntent || (app?.isLaunchable ?? false);
    final l = AppLocalizations.of(context)!;
    await showLauncherDialog<void>(
      context: context,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => SettingsPanelStyle(
        builder: (dialogContext) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
              SidePanelDialog(
                // Nested dialogs use the free area beside the source panel.
                topInset: widget.topInset,
                width: 420,
                isRightSide: widget.isRightSide,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.notificationOptions,
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(name),
                      if (item.title.isNotEmpty)
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (item.text.isNotEmpty) Text(item.text),
                      const Divider(),
                      if (canOpen)
                        FocusableSettingsTile(
                          autofocus: true,
                          leading: const Icon(Icons.launch),
                          title: Text('${l.openApp} $name'),
                          onPressed: () async {
                            if (item.hasContentIntent) {
                              final opened = await service.openNotification(
                                item.key,
                              );
                              if (!dialogContext.mounted) return;
                              if (!opened) {
                                showActionNotice(
                                  dialogContext,
                                  l.notificationOpenFailed,
                                );
                                return;
                              }
                            } else if (app != null) {
                              final opened = await apps.launchApp(app);
                              if (!dialogContext.mounted) return;
                              if (!opened) {
                                showActionNotice(dialogContext, l.notificationOpenFailed);
                                return;
                              }
                            }
                            if (!dialogContext.mounted || !mounted) return;
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      FocusableSettingsTile(
                        autofocus: !canOpen,
                        leading: const Icon(Icons.delete_outline),
                        title: Text(l.delete),
                        onPressed: () async {
                          if (item.isClearable) {
                            Navigator.of(dialogContext).pop();
                          }
                          await _change(item, false);
                        },
                      ),
                      FocusableSettingsTile(
                        autofocus: false,
                        leading: const Icon(Icons.block),
                        title: Text(l.blockAppNotifications),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _change(item, true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _modalOpen = false;
    if (mounted) _restore(item.key, index < 0 ? 0 : index, neighbors);
  }

  @override
  Widget build(BuildContext context) =>
      SettingsPanelStyle(builder: _buildPanel);

  Widget _buildPanel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<NotificationsService>();
    final apps = context.watch<AppsService>();
    final items = service.notifications;
    if (_focusedKey != null && !items.any((n) => n.key == _focusedKey)) {
      final index = _keys.indexOf(_focusedKey!);
      final neighbors = _neighbors(_focusedKey);
      _focusedKey = null;
      _restore(null, index < 0 ? 0 : index, neighbors);
    }
    _keys = items.map((n) => n.key).toList();
    for (final key
        in _nodes.keys.where((key) => !_keys.contains(key)).toList()) {
      final node = _nodes.remove(key)!;
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    return ExcludeFocus(
      excluding: _settingsOpen,
      child: Offstage(
        offstage: _settingsOpen,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: const LauncherPanelBackdrop(
                    key: ValueKey("notification-backdrop"),
                  ),
                ),
              ),
              SidePanelDialog(
                anchor: widget.anchor,
                topInset: widget.topInset,
                width: 420,
                isRightSide: widget.isRightSide,
                child: Column(
                  mainAxisSize: widget.anchor == null
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuHeader(
                      title: Text(l.notifications),
                      actions: [
                        MenuHeaderAction(
                          focusNode: _hideNode,
                          autofocus: items.isEmpty,
                          tooltip: l.hidePersistentNotificationsHint,
                          icon: Icon(
                            service.hidePersistentNotifications
                                ? Icons.notifications_paused
                                : Icons.notifications_paused_outlined,
                          ),
                          onPressed: () async {
                            _focusedKey = null;
                            await service.setHidePersistentNotifications(
                              !service.hidePersistentNotifications,
                            );
                            if (mounted) {
                              _hideNode.requestFocus();
                            }
                          },
                        ),
                        MenuHeaderAction(
                          focusNode: _settingsNode,
                          tooltip: l.notificationSettingsButton,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () async {
                            _modalOpen = true;
                            setState(() => _settingsOpen = true);
                            await showLauncherDialog<void>(
                              context: context,
                              parentPanelHidden: true,
                              styleDialog: false,
                              barrierColor: Colors.transparent,
                              builder: (_) => const SettingsPanel(
                                initialRoute:
                                    NotificationsSettingsPage.routeName,
                              ),
                            );
                            _modalOpen = false;
                            if (mounted) {
                              setState(() => _settingsOpen = false);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _settingsNode.requestFocus();
                              });
                            }
                          },
                        ),
                        if (items.any((n) => n.isClearable))
                          MenuHeaderAction(
                            icon: const Icon(Icons.clear_all),
                            tooltip: l.clearAll,
                            onPressed: () async {
                              _focusedKey = null;
                              await service.dismissAll();
                              if (mounted) _hideNode.requestFocus();
                            },
                          ),
                      ],
                      hint: Text(l.dpadDismissHint),
                    ),
                    const Divider(),
                    Flexible(
                      fit: widget.anchor == null
                          ? FlexFit.tight
                          : FlexFit.loose,
                      child: items.isEmpty
                          ? Center(
                              heightFactor: widget.anchor == null ? null : 1,
                              child: Text(l.allCaughtUp),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: List.generate(items.length, (index) {
                                  final item = items[index];
                                  final app = apps.applications
                                      .firstWhereOrNull(
                                        (a) =>
                                            a.packageName == item.packageName,
                                      );
                                  final name = app?.name ?? item.packageName;
                                  return Focus(
                                    key: ValueKey(item.key),
                                    canRequestFocus: false,
                                    onFocusChange: (focused) {
                                      if (focused) _focusedKey = item.key;
                                    },
                                    child: NoticeSurface(
                                      child: FocusableSettingsTile(
                                        key: ValueKey(
                                          'notification-${item.key}',
                                        ),
                                        autofocus: index == 0,
                                        focusNode: _nodes.putIfAbsent(
                                          item.key,
                                          () => FocusNode(),
                                        ),
                                        leading: FutureBuilder<Uint8List>(
                                          future: apps.getAppIcon(
                                            item.packageName,
                                          ),
                                          builder: (_, snapshot) =>
                                              snapshot.hasData
                                              ? Image.memory(
                                                  snapshot.data!,
                                                  width: 32,
                                                  height: 32,
                                                  cacheWidth: 64,
                                                )
                                              : const Icon(Icons.android),
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: NoticeStyle.of(context)
                                                  .textStyle
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (item.title.isNotEmpty)
                                              Text(
                                                item.title,
                                                style: NoticeStyle.of(context)
                                                    .textStyle,
                                              ),
                                            if (item.text.isNotEmpty)
                                              Text(
                                                item.text,
                                                style: NoticeStyle.of(context)
                                                    .textStyle,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (!item.isClearable)
                                              Text(
                                                l.persistentNotification,
                                                style: NoticeStyle.of(context)
                                                    .textStyle,
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.isClearable)
                                              Tooltip(
                                                message: l.dismiss,
                                                preferBelow: false,
                                                waitDuration: const Duration(
                                                  seconds: 2,
                                                ),
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () =>
                                                      _change(item, false),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const Icon(Icons.chevron_right),
                                          ],
                                        ),
                                        onPressed: () => _options(item, name),
                                        onKeyEvent: (_, event) {
                                          if (event is! KeyDownEvent) {
                                            return KeyEventResult.ignored;
                                          }
                                          if (event.logicalKey ==
                                                  LogicalKeyboardKey.arrowUp ||
                                              event.logicalKey ==
                                                  LogicalKeyboardKey
                                                      .arrowDown) {
                                            ++_restoreGeneration;
                                            final next =
                                                index +
                                                (event.logicalKey ==
                                                        LogicalKeyboardKey
                                                            .arrowUp
                                                    ? -1
                                                    : 1);
                                            if (next < 0) {
                                              _hideNode.requestFocus();
                                            } else if (next < items.length) {
                                              final node =
                                                  _nodes[items[next].key]!;
                                              node.requestFocus();
                                              Scrollable.ensureVisible(
                                                node.context!,
                                                alignment: .5,
                                                duration: const Duration(
                                                  milliseconds: 100,
                                                ),
                                              );
                                            }
                                            return KeyEventResult.handled;
                                          }
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowLeft) {
                                            _change(item, false);
                                            return KeyEventResult.handled;
                                          }
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowRight) {
                                            _change(item, true);
                                            return KeyEventResult.handled;
                                          }
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.contextMenu) {
                                            _options(item, name);
                                            return KeyEventResult.handled;
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
