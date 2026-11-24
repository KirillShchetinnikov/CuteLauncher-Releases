import 'settings_information.dart';
import 'settings_list_heading.dart';
import 'settings_route.dart';
import 'app_channels_settings_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_content_channel.dart';
import '../../providers/app_channels_service.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import 'adb_permission_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class AppChannelsOrderPage extends StatefulWidget {
  static const routeName = 'app_channels_order';
  const AppChannelsOrderPage({super.key});

  @override
  State<AppChannelsOrderPage> createState() => _AppChannelsOrderPageState();
}

class _AppChannelsOrderPageState extends State<AppChannelsOrderPage> {
  final _nodes = <String, FocusNode>{};
  String? _moving;
  bool _revealingEditorRow = false;
  bool _requestingAccess = false;
  Future<void> _moves = Future.value();
  AppChannelsService? _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service = context.read<AppChannelsService>()..openCatalog();
    });
  }

  @override
  void dispose() {
    _service?.closeCatalog();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _requestAccess(AppChannelsService service) async {
    if (_requestingAccess) return;
    setState(() => _requestingAccess = true);
    try {
      await service.channel.requestAppChannelsPermission();
      if (mounted) await service.refresh();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsUnavailable,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _requestingAccess = false);
    }
  }

  static List<String> _hiddenOrder(
    List<String> visible,
    List<String> hidden,
    Map<String, AppContentChannel> channels,
  ) {
    final selected = visible.toSet();
    return {...hidden, ...channels.keys}
        .where(
          (key) => !selected.contains(key) && channels[key]?.hidden != true,
        )
        .toList();
  }

  Future<void> _openEditor(String key) async {
    final settings = context.read<SettingsService>();
    final wasVisible = settings.selectedAppChannels.contains(key);
    await Navigator.of(context).push<void>(
      SettingsRoute(builder: (_) => AppChannelEditorPage(channelKey: key)),
    );
    if (!mounted || wasVisible == settings.selectedAppChannels.contains(key)) {
      return;
    }

    // The row can move beyond the sliver's cache while the editor is open.
    setState(() => _revealingEditorRow = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _revealingEditorRow = false);
      if (ModalRoute.isCurrentOf(context) == false) return;
      _focusRow(key, wasVisible ? 1 : -1);
    });
  }

  void _focusRow(String key, int direction) {
    final node = _nodes[key];
    node?.requestFocus();
    final target = node?.context;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignmentPolicy: direction < 0
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  Future<void> _move(String key, int delta) async {
    final settings = context.read<SettingsService>();
    final channels = {
      for (final channel in context.read<AppChannelsService>().channels)
        channel.key: channel,
    };
    final saved = settings.appChannelsOrder;
    final visible = saved.visible;
    final shown = visible
        .where((key) => channels[key]?.hidden != true)
        .toList();
    final hidden = _hiddenOrder(visible, saved.hidden, channels);
    final isVisible = shown.contains(key);
    final group = isVisible ? shown : hidden;
    final index = group.indexOf(key);
    if (index < 0) return;
    final next = index + delta;
    var hiddenChanged = true;
    if (isVisible && next == shown.length) {
      visible.remove(key);
      hidden.insert(0, key);
    } else if (!isVisible && next < 0) {
      hidden.removeAt(index);
      visible.add(key);
    } else if (next >= 0 && next < group.length) {
      final order = isVisible ? visible : hidden;
      final target = order.indexOf(group[next]);
      order.remove(key);
      order.insert(target, key);
      hiddenChanged = !isVisible;
    } else {
      return;
    }
    try {
      await settings.setAppChannelsOrder(
        visible,
        hiddenChanged
            ? [
                ...hidden,
                ...saved.hidden.where((key) => channels[key]?.hidden == true),
              ]
            : saved.hidden,
      );
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_moving != key && _nodes[key]?.hasFocus != true) return;
        _focusRow(key, delta);
      });
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsSaveFailed,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final saved = context.watch<SettingsService>().appChannelsOrder;
    final service = context.watch<AppChannelsService>();
    final channels = {
      for (final channel in service.channels)
        channel.key: channel,
    };
    final shown = saved.visible
        .where((key) => channels[key]?.hidden != true)
        .toList();
    final hidden = _hiddenOrder(saved.visible, saved.hidden, channels);
    final order = [...shown, ...hidden];
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        footer: order.isEmpty ? null : SettingsControlHint(text: l.appChannelsOrderHint),
        title: Text(l.feedsAndOrder),
        child: ListView(
          scrollCacheExtent: _revealingEditorRow
              ? const ScrollCacheExtent.pixels(double.maxFinite / 4)
              : null,
          children: [
            if (service.unavailable) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.appChannelsUnavailable),
              ),
              FocusableSettingsTile(
                autofocus: order.isEmpty,
                leading: const Icon(Icons.security),
                title: Text(l.appChannelsAccess),
                busy: _requestingAccess,
                onPressed: () => _requestAccess(service),
              ),
              AdbPermissionTile(
                title: '${l.appChannelsAccess} · ADB',
                action: 'watchNext',
                permissionMethod: 'checkAppChannelsPermission',
                onRefresh: service.refresh,
              ),
            ] else if (!service.initialized && order.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (service.initialized && !channels.values.any((channel) => !channel.hidden))
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.appChannelsEmpty),
              ),
            for (final key in order) ...[
              if (key == shown.firstOrNull)
                SettingsListHeading(title: l.visibleFeeds),
              if (key == hidden.firstOrNull)
                SettingsListHeading(title: l.hiddenFeeds),
              FocusableSettingsTile(
                key: ValueKey(key),
                autofocus: key == order.first && _moving == null,
                focusNode: _nodes.putIfAbsent(key, () => FocusNode()),
                leading: Icon(
                  _moving == key ? Icons.drag_indicator : Icons.drag_handle,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channels[key]?.name ?? l.appChannelsMissing),
                    Text(
                      channels[key]?.appName ?? key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                selected: _moving == key,
                showActionChevron: false,
                trailing: _moving == key
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.reorder),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up),
                              Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ],
                      )
                    : null,
                onPressed: () => _moving == key
                    ? setState(() => _moving = null)
                    : _openEditor(key),
                onLongPress: () => setState(() => _moving = key),
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final button = event.logicalKey;
                  if (event is KeyRepeatEvent &&
                      button != LogicalKeyboardKey.arrowUp &&
                      button != LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.handled;
                  }
                  if (event is KeyDownEvent &&
                      (button == LogicalKeyboardKey.arrowLeft ||
                          button == LogicalKeyboardKey.arrowRight)) {
                    setState(() => _moving = _moving == key ? null : key);
                    return KeyEventResult.handled;
                  }
                  if (_moving == key && button == LogicalKeyboardKey.escape) {
                    setState(() => _moving = null);
                    return KeyEventResult.handled;
                  }
                  if (button == LogicalKeyboardKey.arrowUp ||
                      button == LogicalKeyboardKey.arrowDown) {
                    final delta = button == LogicalKeyboardKey.arrowUp ? -1 : 1;
                    if (_moving == key) {
                      // Keep each step while the previous one is being saved.
                      _moves = _moves.then((_) async {
                        if (mounted) await _move(key, delta);
                      });
                    } else {
                      final next = order.indexOf(key) + delta;
                      if (next < 0 || next >= order.length) {
                        return KeyEventResult.ignored;
                      }
                      _nodes[order[next]]?.requestFocus();
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
              ),
            ],
            if (service.initialized)
              SettingsHelp(title: l.appChannelsTitle, text: l.appChannelsHelp),
          ],
        ),
      ),
    );
  }
}
