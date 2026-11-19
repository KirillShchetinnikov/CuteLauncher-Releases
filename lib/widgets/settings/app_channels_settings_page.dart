import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../feed_format.dart';
import '../../providers/app_channels_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/apps_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'adb_permission_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_slider_tile.dart';
import 'settings_value_stepper.dart';
import 'app_channels_order_page.dart';
import 'settings_section.dart';
import 'settings_route.dart';
import 'app_channels_appearance_page.dart';

class AppChannelsSettingsPage extends StatefulWidget {
  static const routeName = 'app_channels_settings';
  final String? channelKey;
  const AppChannelsSettingsPage({super.key, this.channelKey});
  @override
  State<AppChannelsSettingsPage> createState() =>
      _AppChannelsSettingsPageState();
}

class _AppChannelsSettingsPageState extends State<AppChannelsSettingsPage>
    with WidgetsBindingObserver {
  static final _cardLimits = List<int>.generate(
    SettingsService.maxAppChannelCardLimit -
        SettingsService.minAppChannelCardLimit + 1,
    (index) => SettingsService.minAppChannelCardLimit + index,
  );

  bool _busy = false;
  AppChannelsService? _service;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _service = context.read<AppChannelsService>()..openCatalog();
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _service?.closeCatalog();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _refresh();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<AppChannelsService>().refresh(reloadPosters: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _select(String key, bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsService>();
      final selected = settings.selectedAppChannels.toList()..remove(key);
      if (enabled) selected.add(key);
      await settings.setSelectedAppChannels(selected);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _revealMovedSwitch(key);
      });
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsSaveFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _revealMovedSwitch(String key) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null ||
        context.findAncestorWidgetOfExactType<RoundedSwitchListTile>()?.key !=
            ValueKey(key)) {
      return;
    }
    final scrollable = Scrollable.maybeOf(context);
    final target = context.findRenderObject();
    if (scrollable == null || target == null || !target.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(target);
    if (viewport == null) return;
    final start = viewport.getOffsetToReveal(target, 0).offset;
    Scrollable.ensureVisible(
      context,
      alignmentPolicy: start < scrollable.position.pixels
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  Future<void> _requestAccess() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context
          .read<AppChannelsService>()
          .channel
          .requestAppChannelsPermission();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsUnavailable,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _refresh();
  }

  Future<void> _saveSetting(
    Future<void> Function(SettingsService) save,
  ) async {
    try {
      await save(context.read<SettingsService>());
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
    final service = context.watch<AppChannelsService>();
    final settings = context.watch<SettingsService>();
    final categoryId = context.watch<AppsService?>()?.categories.where((category) => category.isAppChannels).firstOrNull?.id;
    final selected = settings.selectedAppChannels;
    final availableChannels =
        service.channels.where((channel) => !channel.hidden);
    final channels = [
      for (final key in selected)
        ...availableChannels.where((c) => c.key == key),
      ...availableChannels.where((c) => !selected.contains(c.key)),
    ];
    final key = widget.channelKey;
    if (key != null) {
      final matches = channels.where((channel) => channel.key == key);
      final channel = matches.isEmpty ? null : matches.first;
      return SettingsPageLayout(
        title: Text(channel?.name ?? l.appChannelsMissing),
        child: ListView(children: [
          RoundedSwitchListTile(
            key: ValueKey(key), title: Text(l.categoryVisible),
            value: selected.contains(key), busy: _busy,
            onChanged: (value) => _select(key, value),
          ),
          SettingsValueStepper(
            key: ValueKey('format:$key'), title: l.feedFormat,
            value: settings.appChannelFormat(key), options: FeedFormat.values,
            label: (value) => switch (value as FeedFormat) {
              FeedFormat.auto => l.feedFormatAuto,
              FeedFormat.landscape => l.feedFormatLandscape,
              FeedFormat.portrait => l.feedFormatPortrait,
            },
            onChanged: (value) => _saveSetting((s) => s.setAppChannelFormat(key, value as FeedFormat)),
          ),
          SettingsHelp(title: l.feedFormat, text: l.feedFormatHelp),
        ]),
      );
    }
    return SettingsPageLayout(
      title: Text(l.appChannelsTitle),
      // A focused switch can move outside the viewport in either direction.
      // Lay out all catalogue rows so its new position is available at once.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(title: l.appChannelsTitle, children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.view_list_outlined),
                title: Text(l.feedsAndOrder),
                trailing: Text('${selected.length} / ${channels.length}'),
                onPressed: () => Navigator.of(context).pushNamed(AppChannelsOrderPage.routeName),
              ),
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.refresh),
              title: Text(l.appChannelsRefresh),
              // Keep the row focusable while its action is busy.
              onPressed: _busy ? null : _refresh,
              trailing: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                  : null,
            ),
            ]),
            SettingsHelp(
              title: l.appChannelsTitle,
              text: '${l.appChannelsHelp}\n\n${l.feedFormatHelp}',
            ),
            SettingsSliderTile(
              title: l.maximumItems,
              options: _cardLimits,
              value: settings.appChannelCardLimit,
              label: (value) => MaterialLocalizations.of(context)
                  .formatDecimal(value.toInt()),
              onChanged: (value) => _saveSetting(
                (s) => s.setAppChannelCardLimit(value.toInt()),
              ),
            ),
            if (categoryId != null)
              FocusableSettingsTile(
                title: Text(l.appearanceSettings), leading: const Icon(Icons.palette_outlined),
                onPressed: () => Navigator.of(context).push(SettingsRoute(
                  builder: (_) => AppChannelsAppearancePage(categoryId: categoryId),
                )),
              ),
            if (service.unavailable) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.appChannelsUnavailable),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.security),
                title: Text(l.appChannelsAccess),
                busy: _busy,
                onPressed: _requestAccess,
              ),
              AdbPermissionTile(
                title: '${l.appChannelsAccess} · ADB',
                action: 'watchNext',
                permissionMethod: 'checkAppChannelsPermission',
                onRefresh: service.refresh,
              ),
            ] else if (service.initialized && channels.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.appChannelsEmpty),
              ),

          ],
        ),
      ),
    );
  }
}
