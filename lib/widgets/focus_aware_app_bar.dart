import 'panel_calendar_dialog.dart';
import 'panel_clock.dart';
import '../providers/remote_panel_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../providers/apps_service.dart';
import '../providers/tv_inputs_service.dart';
import '../providers/notifications_service.dart';
import '../providers/weather_service.dart';
import '../providers/network_service.dart';
import '../tile_appearance.dart';
import 'appearance_surface.dart';
import 'android_settings_icon.dart';
import 'daily_data_usage_widget.dart';
import 'date_time_widget.dart';
import 'network_widget.dart';
import 'weather_status_bar_widget.dart';
import 'top_panel_item.dart';
import 'settings/settings_panel.dart';
import 'settings/inputs_panel.dart';
import 'settings/notifications_panel.dart';
import '../l10n/app_localizations.dart';
import '../providers/sleep_timer_service.dart';
import 'sleep_timer_menu.dart';
import '../providers/night_mode_service.dart';
import 'night_mode_menu.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  final RemotePanelService? remotePanel;
  const FocusAwareAppBar({super.key, this.remotePanel});
  @override
  State<FocusAwareAppBar> createState() => FocusAwareAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class FocusAwareAppBarState extends State<FocusAwareAppBar> {
  bool focused = false;
  bool _settingsOpen = false;
  String? _activeWidget;
  void _setOpenWidget(String? id) => setState(() {
    _settingsOpen = id != null;
    _activeWidget = id;
  });
  final _settingsFocusNode = FocusNode();
  final _systemSettingsFocusNode = FocusNode();
  final _inputsFocusNode = FocusNode();
  final _notificationsFocusNode = FocusNode();
  final _sleepTimerFocusNode = FocusNode();
  final _nightModeFocusNode = FocusNode();
  final _dateFocusNode = FocusNode();
  FocusNode get dateFocusNode => _dateFocusNode;
  FocusNode get settingsFocusNode => _settingsFocusNode;
  FocusNode get systemSettingsFocusNode => _systemSettingsFocusNode;
  FocusNode get inputsFocusNode => _inputsFocusNode;
  FocusNode get notificationsFocusNode => _notificationsFocusNode;
  void focusSettings() => _settingsFocusNode.requestFocus();
  void focusFirst() {
    final nodes = {'settings': _settingsFocusNode, 'systemSettings': _systemSettingsFocusNode,
      'inputs': _inputsFocusNode, 'notifications': _notificationsFocusNode,
      'sleepTimer': _sleepTimerFocusNode, 'nightMode': _nightModeFocusNode, 'date': _dateFocusNode};
    final layout = widget.remotePanel?.layout ??
        (context.read<AppearanceService?>()?.appearance ?? const TileAppearance()).panelLayout;
    for (final id in [...layout.left, ...layout.right]) {
      final node = nodes[id];
      if (node?.context != null) { node!.requestFocus(); return; }
    }
    FocusScope.of(context).nextFocus();
  }

  bool _buttonOnRight(FocusNode node) {
    final box = node.context?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(box.size.center(Offset.zero)).dx >
          MediaQuery.sizeOf(context).width / 2;
    }
    return false;
  }

  Future<void> _openButtonPanel(FocusNode node, bool inputs) async {
    final box = node.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final onRight = _buttonOnRight(node);
    _setOpenWidget(inputs ? 'inputs' : 'notifications');
    if (inputs) {
      try {
        await context.read<TvInputsService>().refreshInputs();
      } catch (e) {
        debugPrint('Unable to refresh TV inputs: $e');
      }
      if (!mounted) return;
    }
    await showLauncherDialog<void>(
      context: context,
      highlightRect: anchor,
      useSafeArea: false,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => inputs
          ? InputsPanel(isRightSide: onRight, topInset: kToolbarHeight, anchor: anchor)
          : NotificationsPanel(isRightSide: onRight, topInset: kToolbarHeight, anchor: anchor),
    );
    if (mounted) {
      _setOpenWidget(null);
      if (node.context != null) {
        node.requestFocus();
      } else {
        _settingsFocusNode.requestFocus();
      }
    }
  }

  final _objectKeys = <String, GlobalKey>{};
  @override
  void dispose() {
    for (final node in [
      _settingsFocusNode,
      _systemSettingsFocusNode,
      _inputsFocusNode,
      _notificationsFocusNode,
      _sleepTimerFocusNode,
      _nightModeFocusNode,
      _dateFocusNode,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => const SettingsPanel(),
    );
    if (mounted) setState(() => _settingsOpen = false);
  }

  Future<void> _openCalendar() async {
    final box = _dateFocusNode.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _setOpenWidget('date');
    try {
      await showLauncherDialog<void>(
        context: context,
        highlightRect: anchor,
        barrierColor: Colors.transparent,
        useSafeArea: false,
        builder: (_) => PanelCalendarDialog(anchor: anchor),
      );
    } finally {
      if (mounted) {
        _setOpenWidget(null);
        if (_dateFocusNode.context != null) {
          _dateFocusNode.requestFocus();
        } else {
          focusFirst();
        }
      }
    }
  }

  Future<void> _openNightMode() async {
    final box = _nightModeFocusNode.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _setOpenWidget('nightMode');
    await showLauncherDialog<void>(
      context: context,
      highlightRect: anchor,
      useSafeArea: false,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => NightModeMenu(anchor: anchor),
    );
    if (mounted) {
      _setOpenWidget(null);
      if (_nightModeFocusNode.context != null) {
        _nightModeFocusNode.requestFocus();
      } else {
        _settingsFocusNode.requestFocus();
      }
    }
  }

  Future<void> _openSleepTimer() async {
    final box = _sleepTimerFocusNode.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _setOpenWidget('sleepTimer');
    final timer = context.read<SleepTimerService>();
    await timer.refresh();
    if (!mounted) return;
    await showLauncherDialog<void>(
      context: context,
      highlightRect: anchor,
      useSafeArea: false,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => SleepTimerMenu(anchor: anchor),
    );
    if (mounted) {
      _setOpenWidget(null);
      if (_sleepTimerFocusNode.context != null) {
        _sleepTimerFocusNode.requestFocus();
      } else {
        _settingsFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAppearance = context.watch<AppearanceService?>()?.appearance ?? const TileAppearance();
    final appearance = widget.remotePanel?.appearanceFor(homeAppearance) ?? homeAppearance;
    final settings = context.watch<SettingsService>();
    final inputs = context.watch<TvInputsService>();
    final notifications = context.watch<NotificationsService>();
    final weather = context.watch<WeatherService>();
    final timer = context.watch<SleepTimerService?>();
    final night = context.watch<NightModeService?>();
    final direction = TextDirection.ltr;
    final objects = <String, Widget>{
      if (widget.remotePanel?.visible('settings') ?? true) 'settings': TopPanelItem(
        focusNode: _settingsFocusNode,
        onPressed: _openSettings,
        child: const Icon(Icons.settings_outlined),
      ),
      if ((widget.remotePanel?.visible('systemSettings') ?? settings.showSystemSettingsInStatusBar))
        'systemSettings': TopPanelItem(
          focusNode: _systemSettingsFocusNode,
          onPressed: () => context.read<AppsService>().openSettings(),
          child: AndroidSettingsIcon(
            size: appearance.panelTextSize,
            color: appearance.panelTextColor,
          ),
        ),
      if ((widget.remotePanel?.visible('inputs') ?? settings.showInputsWidgetInStatusBar) && inputs.hasInputs)
        'inputs': TopPanelItem(
          focusNode: _inputsFocusNode,
          selected: _activeWidget == 'inputs',
          onPressed: () => _openButtonPanel(_inputsFocusNode, true),
          child: const Icon(Icons.tv_outlined),
        ),
      if ((widget.remotePanel?.visible('notifications') ?? settings.showNotificationsWidgetInStatusBar) &&
          notifications.hasPermission &&
          (!settings.autoHideNotificationsWidget ||
              notifications.notifications.isNotEmpty))
        'notifications': TopPanelItem(
          focusNode: _notificationsFocusNode,
          selected: _activeWidget == 'notifications',
          onPressed: () => _openButtonPanel(_notificationsFocusNode, false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: direction,
            children: [
              Icon(
                notifications.notifications.isNotEmpty
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_outlined,
              ),
              if (notifications.notifications.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text('${notifications.notifications.length}'),
              ],
            ],
          ),
        ),
      if ((widget.remotePanel?.visible('sleepTimer') ?? settings.showSleepTimerInStatusBar))
        'sleepTimer': Semantics(
          label: AppLocalizations.of(context)?.sleepTimer,
          child: TopPanelItem(
            focusNode: _sleepTimerFocusNode,
            selected: _activeWidget == 'sleepTimer',
            onPressed: _openSleepTimer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: direction,
              children: [
                if (timer?.active ?? false) ...[
                  Text(timer!.countdown),
                  const SizedBox(width: 4),
                ],
                Icon((timer?.active ?? false) ? Icons.power_settings_new : Icons.timer_outlined),
              ],
            ),
          ),
        ),
      if ((widget.remotePanel?.visible('nightMode') ?? settings.showNightModeInStatusBar) && night != null)
        'nightMode': Semantics(
          label: AppLocalizations.of(context)?.nightModeTitle,
          toggled: night.intensity > 0,
          child: TopPanelItem(
            key: const ValueKey('night_mode_button'),
            focusNode: _nightModeFocusNode,
            selected: _activeWidget == 'nightMode',
            onPressed: _openNightMode,
            child: Icon(night.intensity > 0
                ? Icons.nightlight_round : Icons.nightlight_outlined),
          ),
        ),
      if ((widget.remotePanel?.visible('network') ?? settings.showNetworkIndicatorInStatusBar))
        'network': const NetworkWidget(),
      if ((widget.remotePanel?.visible('traffic') ?? settings.showDataWidgetInStatusBar) &&
          context.watch<NetworkService>().hasUsageStatsPermission)
        'traffic': const TopPanelItem(child: DailyDataUsageWidget()),
      if ((widget.remotePanel?.visible('weather') ?? settings.showWeatherInStatusBar) && weather.hasWeather)
        'weather': WeatherStatusBarWidget(
          showWeather: widget.remotePanel == null ? null : true,
        ),
      if ((widget.remotePanel?.visible('date') ?? settings.showDateInStatusBar))
        'date': TopPanelItem(
          focusNode: _dateFocusNode,
          selected: _activeWidget == 'date',
          onPressed: (widget.remotePanel?.dateCalendar ?? appearance.dateCalendar) ? _openCalendar : null,
          child: DateTimeWidget(
            settings.dateFormat,
            key: const Key('statusbar_date'),
            textStyle: appearance.panelTextStyle,
          ),
        ),
      if ((widget.remotePanel?.visible('time') ?? settings.showTimeInStatusBar))
        'time': PanelClock(
          style: homeAppearance.clockStyle,
          format: settings.timeFormat,
        ),
    };
    Widget group(String key) {
      final layout = widget.remotePanel?.layout ?? appearance.panelLayout;
      final order = (key == 'panelButtonsOrder' ? layout.left : layout.right)
          .where(objects.containsKey)
          .toList();
      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: direction,
        children: [
          for (var i = 0; i < order.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            KeyedSubtree(key: _objectKeys.putIfAbsent(order[i], () => GlobalKey()), child: objects[order[i]]!),
          ],
        ],
      );
    }

    final left = group('panelButtonsOrder');
    final right = group('panelInfoOrder');
    final panel = PanelAppearanceScope(appearance: appearance, child: RepaintBoundary(
      child: AppBar(
        flexibleSpace: widget.remotePanel != null ? ColoredBox(
          color: (appearance.color('panelColor') ?? Colors.black).withValues(alpha: appearance.number('panelOpacity') ?? 0),
          child: const SizedBox.expand()) : PanelAppearanceSurface(
          appearance: appearance,
          child: const SizedBox.expand(),
        ),
        titleSpacing: 24,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: LayoutBuilder(
          builder: (context, constraints) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [left, const SizedBox(width: 12), right],
              ),
            ),
          ),
        ),
      ),
    ));
    return Focus(
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => focused = value),
      child: AnimatedContainer(
        key: const Key('top_panel_visibility'),
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        height: widget.remotePanel == null && settings.autoHideAppBarEnabled && !focused && !_settingsOpen
            ? 0
            : kToolbarHeight,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: panel,
      ),
    );
  }
}
