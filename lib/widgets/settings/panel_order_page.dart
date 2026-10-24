import '../../panel_layout.dart';
import '../../providers/remote_panel_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_text.dart';

class PanelOrderPage extends StatefulWidget {
  static const routeName = 'panel_order';
  final bool remotePanel;
  const PanelOrderPage({super.key, this.remotePanel = false});
  @override
  State<PanelOrderPage> createState() => _PanelOrderPageState();
}

class _PanelOrderPageState extends State<PanelOrderPage> {
  final Map<String, FocusNode> _nodes = {};
  String? _moving;
  bool _busy = false;
  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _move(String key, String id, int delta) async {
    if (_busy) return;
    final service = context.read<AppearanceService>();
    final panel = widget.remotePanel
        ? context.read<RemotePanelService>()
        : null;
    final layout = panel?.layout ?? service.appearance.panelLayout;
    final left = key == 'panelButtonsOrder';
    final (first, second) = layout.displayOrders(
      service.appearance.combinedInformation,
    );
    final order = left ? first : second;
    final other = left ? second : first;
    final index = order.indexOf(id);
    final next = index + delta;
    if (next < 0 && !left) {
      order.removeAt(index);
      other.add(id);
    } else if (next == order.length && left) {
      order.removeAt(index);
      other.insert(0, id);
    } else if (next >= 0 && next < order.length) {
      order.removeAt(index);
      order.insert(next, id);
    } else {
      return;
    }
    final (savedLeft, savedRight) = layout.expandOrders(first, second);
    _busy = true;
    try {
      if (panel != null) {
        await panel.setPanelOrder(savedLeft, savedRight);
      } else {
        await service.setPanelOrder(savedLeft, savedRight);
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final node = _nodes[id];
          node?.requestFocus();
          if (node?.context != null) {
            Scrollable.ensureVisible(
              node!.context!,
              alignment: 0.5,
              duration: const Duration(milliseconds: 100),
            );
          }
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final appearance = context.watch<AppearanceService>().appearance;
    final panel = widget.remotePanel
        ? context.watch<RemotePanelService>()
        : null;
    final (leftOrder, rightOrder) = (panel?.layout ?? appearance.panelLayout)
        .displayOrders(appearance.combinedInformation);
    final labels = {
      PanelLayout.informationGroup: l.informationGroup,
      'settings': l.settings,
      'systemSettings': l.androidTvSettings,
      'inputs': l.inputs,
      'notifications': l.notificationBell,
      'sleepTimer': l.sleepTimer,
      'nightMode': l.nightModeTitle,
      'network': l.showNetwork,
      'traffic': l.showTraffic,
      'weather': l.weather,
      'date': l.showDate,
      'time': l.showTime,
    };
    const icons = {
      PanelLayout.informationGroup: Icons.dashboard_outlined,
      'settings': Icons.settings_outlined,
      'systemSettings': Icons.settings,
      'inputs': Icons.tv,
      'notifications': Icons.notifications_outlined,
      'sleepTimer': Icons.timer_outlined,
      'nightMode': Icons.nightlight_round,
      'network': Icons.wifi,
      'traffic': Icons.data_usage,
      'weather': Icons.wb_sunny_outlined,
      'date': Icons.calendar_today,
      'time': Icons.watch_later_outlined,
    };
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text(l.panelObjectOrder),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final key in ['panelButtonsOrder', 'panelInfoOrder']) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SettingsValueText(
                    alignment: TextAlign.start,
                    text: Text(
                      key == 'panelButtonsOrder'
                          ? l.settingsMenuLeft
                          : l.settingsMenuRight,
                    ),
                  ),
                ),
                for (final id
                    in key == 'panelButtonsOrder' ? leftOrder : rightOrder)
                  FocusableSettingsTile(
                    key: ValueKey(id),
                    focusNode: _nodes.putIfAbsent(id, () => FocusNode()),
                    title: Text(labels[id]!),
                    leading: Icon(icons[id]),
                    selected: _moving == id,
                    trailing: Icon(
                      _moving == id ? Icons.unfold_more : Icons.swap_vert,
                    ),
                    onPressed: () =>
                        setState(() => _moving = _moving == id ? null : id),
                    onLongPress: () => setState(() => _moving = id),
                    onKeyEvent: (_, event) {
                      if (_moving == null &&
                          event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.arrowDown)) {
                        final ids = [...leftOrder, ...rightOrder];
                        final next =
                            ids.indexOf(id) +
                            (event.logicalKey == LogicalKeyboardKey.arrowDown
                                ? 1
                                : -1);
                        if (next >= 0 && next < ids.length) {
                          _nodes[ids[next]]?.requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      }
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight)) {
                        setState(() => _moving = _moving == id ? null : id);
                        return KeyEventResult.handled;
                      }
                      if (_moving == id &&
                          event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        setState(() => _moving = null);
                        return KeyEventResult.handled;
                      }
                      if (_moving == id &&
                          (event is KeyDownEvent || event is KeyRepeatEvent)) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                            event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _move(
                            key,
                            id,
                            event.logicalKey == LogicalKeyboardKey.arrowUp
                                ? -1
                                : 1,
                          );
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
              ],
              Text(l.panelOrderHint),
            ],
          ),
        ),
      ),
    );
  }
}
