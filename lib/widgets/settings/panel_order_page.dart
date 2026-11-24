import 'settings_information.dart';
import 'settings_reorder_controls.dart';
import 'settings_help.dart';
import '../../providers/network_service.dart';
import '../../providers/notifications_service.dart';
import '../../providers/storage_status_service.dart';
import '../../providers/tv_inputs_service.dart';
import '../storage_status_watch.dart';
import '../action_notice.dart';
import '../android_settings_icon.dart';
import '../../panel_layout.dart';
import '../../information_placement.dart';
import '../../providers/settings_service.dart';
import '../../providers/remote_panel_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_list_heading.dart';

class PanelOrderPage extends StatefulWidget {
  static const routeName = 'panel_order';
  final bool remotePanel;
  final bool editVisibility;
  const PanelOrderPage({
    super.key,
    this.remotePanel = false,
    this.editVisibility = false,
  });
  @override
  State<PanelOrderPage> createState() => _PanelOrderPageState();
}

class _PanelOrderPageState extends State<PanelOrderPage> {
  final Map<String, FocusNode> _nodes = {};
  String? _moving;
  bool? _focusedCanToggle;
  Future<void> _moves = Future.value();
  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _move(String id, int delta) async {
    final service = context.read<AppearanceService>();
    final panel = widget.remotePanel
        ? context.read<RemotePanelService>()
        : null;
    final layout = panel?.layout ?? service.appearance.panelLayout;
    final composition = InformationPanelComposition(
      service.appearance,
      context.read<SettingsService>(),
      remote: panel,
    );
    final excluded = widget.editVisibility && widget.remotePanel
        ? <String>{}
        : composition.excluded;
    final (first, second) = layout.displayOrders(
      composition.combined && !(widget.editVisibility && widget.remotePanel),
      excluded: excluded,
    );
    final left = first.contains(id);
    final order = left ? first : second;
    final other = left ? second : first;
    final index = order.indexOf(id);
    if (index < 0) return;
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
    final (savedLeft, savedRight) = layout.expandOrders(
      first,
      second,
      excluded: excluded,
    );
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
          if (_moving != id && node?.hasFocus != true) return;
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
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appError,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final appearance = context.watch<AppearanceService>().appearance;
    final panel = widget.remotePanel
        ? context.watch<RemotePanelService>()
        : null;
    final composition = InformationPanelComposition(
      appearance,
      context.watch<SettingsService>(),
      remote: panel,
    );
    final settings = context.watch<SettingsService>();
    final excluded = widget.editVisibility && widget.remotePanel
        ? <String>{}
        : composition.excluded;
    final (
      leftOrder,
      rightOrder,
    ) = (panel?.layout ?? appearance.panelLayout).displayOrders(
      composition.combined && !(widget.editVisibility && widget.remotePanel),
      excluded: excluded,
    );
    final inputs = context.watch<TvInputsService?>();
    final storage = context.watch<StorageStatusService?>();
    final network = context.watch<NetworkService?>();
    final notifications = context.watch<NotificationsService?>();
    bool available(String id) =>
        !widget.editVisibility ||
        switch (id) {
          'inputs' => inputs?.hasInputs == true,
          'nas' => storage?.state.nasSupported == true,
          'traffic' when widget.remotePanel =>
            network?.hasUsageStatsPermission == true,
          'notifications' when widget.remotePanel =>
            notifications?.hasPermission == true,
          _ => true,
        };
    (bool, ValueChanged<bool>)? visibility(String id) {
      if (!widget.editVisibility) return null;
      if (panel != null) {
        return (panel.visible(id), (value) => panel.show(id, value));
      }
      return switch (id) {
        'systemSettings' => (
          settings.showSystemSettingsInStatusBar,
          settings.setShowSystemSettingsInStatusBar,
        ),
        'inputs' => (
          settings.showInputsWidgetInStatusBar,
          settings.setShowInputsWidgetInStatusBar,
        ),
        'notifications' => (
          settings.showNotificationsWidgetInStatusBar,
          settings.setShowNotificationsWidgetInStatusBar,
        ),
        'sleepTimer' => (
          settings.showSleepTimerInStatusBar,
          settings.setShowSleepTimerInStatusBar,
        ),
        PanelLayout.quickActions => (
          settings.showQuickActionsInStatusBar,
          settings.setShowQuickActionsInStatusBar,
        ),
        'nightMode' => (
          settings.showNightModeInStatusBar,
          settings.setShowNightModeInStatusBar,
        ),
        'nas' => (settings.showNasInStatusBar, settings.setShowNasInStatusBar),
        'usb' => (settings.showUsbInStatusBar, settings.setShowUsbInStatusBar),
        'network' => (
          settings.showNetworkIndicatorInStatusBar,
          settings.setShowNetworkIndicatorInStatusBar,
        ),
        'vpn' => (settings.showVpnInStatusBar, settings.setShowVpnInStatusBar),
        'traffic' => (
          settings.showDataWidgetInStatusBar,
          settings.setShowDataWidgetInStatusBar,
        ),
        'networkSpeed' => (
          settings.showNetworkSpeedInStatusBar,
          settings.setShowNetworkSpeedInStatusBar,
        ),
        'system' => (
          settings.showSystemInStatusBar,
          settings.setShowSystemInStatusBar,
        ),
        'audio' => (
          settings.showVolumeInStatusBar,
          settings.setShowVolumeInStatusBar,
        ),
        _ => null,
      };
    }

    final labels = {
      PanelLayout.informationGroup: [
        if (!excluded.contains('time')) l.informationTime,
        if (!excluded.contains('date')) l.informationDate,
        if (!excluded.contains('weather')) l.weather,
      ].join(' · '),
      'settings': l.settings,
      'systemSettings': l.androidTvSettings,
      'inputs': l.inputs,
      'notifications': l.notificationBell,
      'sleepTimer': l.sleepTimer,
      PanelLayout.quickActions: l.quickActionsTitle,
      'nightMode': l.nightModeTitle,
      'nas': l.networkStorageTitle,
      'usb': l.usbStorageTitle,
      'network': l.showNetwork,
      'vpn': l.vpnTitle,
      'traffic': l.showTraffic,
      'networkSpeed': l.networkSpeedTitle,
      'weather': l.weather,
      'system': l.system,
      'audio': l.audioStatusTitle,
      'date': l.showDate,
      'time': l.showTime,
    };
    const icons = {
      PanelLayout.informationGroup: Icons.dashboard_outlined,
      'settings': Icons.settings_outlined,
      'inputs': Icons.tv,
      'notifications': Icons.notifications_outlined,
      'sleepTimer': Icons.timer_outlined,
      PanelLayout.quickActions: Icons.bolt_outlined,
      'nightMode': Icons.nightlight_round,
      'nas': Icons.dns_outlined,
      'usb': Icons.usb,
      'network': Icons.wifi,
      'vpn': Icons.vpn_key,
      'traffic': Icons.data_usage,
      'networkSpeed': Icons.speed,
      'weather': Icons.wb_sunny_outlined,
      'system': Icons.monitor_heart_outlined,
      'audio': Icons.volume_up_outlined,
      'date': Icons.calendar_today,
      'time': Icons.watch_later_outlined,
    };
    final canToggle = _focusedCanToggle ?? (panel != null);
    final hint = !widget.editVisibility
        ? l.panelOrderHint
        : _moving != null
        ? l.applicationInfoMovingHint
        : canToggle
        ? l.applicationInfoButtonsHint
        : 'OK — ${l.reorder}';
    return StorageStatusWatch(
      visible:
          widget.editVisibility && ModalRoute.isCurrentOf(context) != false,
      child: PopScope(
        canPop: _moving == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _moving != null) setState(() => _moving = null);
        },
        child: SettingsPageLayout(
          footer: SettingsControlHint(text: hint),
          title: Text(
            widget.editVisibility
                ? (widget.remotePanel
                      ? l.quickPanelObjectsTitle
                      : l.topPanelObjectsTitle)
                : l.panelObjectOrder,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final key in ['panelButtonsOrder', 'panelInfoOrder']) ...[
                  SettingsListHeading(
                    title: key == 'panelButtonsOrder'
                        ? l.settingsMenuLeft
                        : l.settingsMenuRight,
                  ),
                  for (final id
                      in key == 'panelButtonsOrder' ? leftOrder : rightOrder)
                    FocusableSettingsTile(
                      key: ValueKey(id),
                      focusNode: _nodes.putIfAbsent(id, () => FocusNode()),
                      title: Text(labels[id]!),
                      leading: id == 'systemSettings'
                          ? const AndroidSettingsIcon()
                          : Icon(icons[id]),
                      selected: _moving == id,
                      onFocusChange: (focused) {
                        if (!focused || !widget.editVisibility) return;
                        final canToggle = visibility(id) != null;
                        if (_focusedCanToggle != canToggle) {
                          setState(() => _focusedCanToggle = canToggle);
                        }
                      },
                      enabled: available(id),
                      busy: _moving != null && _moving != id,
                      toggled:
                          (widget.remotePanel || id == 'nas') && !available(id)
                          ? false
                          : visibility(id)?.$1,
                      trailing: widget.editVisibility
                          ? SettingsReorderControls(
                              value:
                                  (widget.remotePanel || id == 'nas') &&
                                      !available(id)
                                  ? false
                                  : visibility(id)?.$1,
                              moving: _moving == id,
                              enabled: available(id),
                              onReorder: () => setState(
                                () => _moving = _moving == id ? null : id,
                              ),
                            )
                          : _moving == id
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.reorder),
                                const Icon(Icons.unfold_more),
                              ],
                            )
                          : const Icon(Icons.swap_vert),
                      onPressed: () {
                        final toggle = visibility(id);
                        if (_moving == null && toggle != null) {
                          toggle.$2(!toggle.$1);
                        } else {
                          setState(() => _moving = _moving == id ? null : id);
                        }
                      },
                      onLongPress: () => setState(() => _moving = id),
                      onKeyEvent: (_, event) {
                        if (_moving == null &&
                            event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowDown)) {
                          final ids = [
                            ...leftOrder,
                            ...rightOrder,
                          ].where(available).toList();
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
                            (event is KeyDownEvent ||
                                event is KeyRepeatEvent)) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.arrowDown) {
                            final delta =
                                event.logicalKey == LogicalKeyboardKey.arrowUp
                                ? -1
                                : 1;
                            _moves = _moves.then((_) async {
                              if (mounted) await _move(id, delta);
                            });
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                    ),
                ],
                if (widget.editVisibility &&
                    inputs?.initialized == true &&
                    !inputs!.hasInputs)
                  SettingsHelp(title: l.inputs, text: l.inputsUnavailableHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
