import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../feed_format.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_channels_service.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'memory_settings_page.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_section.dart';
import 'settings_slider_tile.dart';
import 'settings_value_stepper.dart';

class AppChannelsSectionSettingsPage extends StatelessWidget {
  const AppChannelsSectionSettingsPage({super.key});

  static final _cardLimits = List<int>.generate(
    SettingsService.maxAppChannelCardLimit -
        SettingsService.minAppChannelCardLimit +
        1,
    (index) => SettingsService.minAppChannelCardLimit + index,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final limit = context.select(
      (SettingsService settings) => settings.appChannelCardLimit,
    );
    return SettingsPageLayout(
      title: Text(l.appChannelsSectionSettings),
      child: ListView(
        children: [
          SettingsSection(
            children: [
              SettingsSliderTile(
                autofocus: true,
                title: l.maximumItems,
                options: _cardLimits,
                value: limit,
                label: (value) =>
                    MaterialLocalizations.of(context)
                        .formatDecimal(value.toInt()),
                onChanged: (value) => _saveSetting(
                  context,
                  (settings) => settings.setAppChannelCardLimit(value.toInt()),
                ),
              ),
              const PosterMemoryLink(PosterCacheSection.appChannels, fromSection: true),
            ],
          ),
        ],
      ),
    );
  }
}

class AppChannelEditorPage extends StatefulWidget {
  const AppChannelEditorPage({super.key, required this.channelKey});

  final String channelKey;

  @override
  State<AppChannelEditorPage> createState() => _AppChannelEditorPageState();
}

class _AppChannelEditorPageState extends State<AppChannelEditorPage> {
  bool _busy = false;

  Future<void> _select(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    final key = widget.channelKey;
    try {
      await _saveSetting(context, (settings) async {
        final selected = settings.selectedAppChannels.toList()..remove(key);
        if (enabled) selected.add(key);
        await settings.setSelectedAppChannels(selected);
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _revealMovedSwitch(key);
        });
      });
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final key = widget.channelKey;
    final channel = context
        .watch<AppChannelsService>()
        .channels
        .where((channel) => !channel.hidden && channel.key == key)
        .firstOrNull;
    return SettingsPageLayout(
      title: Text(channel?.name ?? l.appChannelsMissing),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            key: ValueKey(key),
            title: Text(l.appChannelVisible),
            value: settings.selectedAppChannels.contains(key),
            busy: _busy,
            onChanged: _select,
          ),
          SettingsValueStepper(
            key: ValueKey('format:$key'),
            title: l.feedFormat,
            value: settings.appChannelFormat(key),
            options: FeedFormat.values,
            label: (value) => switch (value as FeedFormat) {
              FeedFormat.auto => l.feedFormatAuto,
              FeedFormat.landscape => l.feedFormatLandscape,
              FeedFormat.portrait => l.feedFormatPortrait,
            },
            onChanged: (value) => _saveSetting(
              context,
              (settings) =>
                  settings.setAppChannelFormat(key, value as FeedFormat),
            ),
          ),
          SettingsHelp(title: l.feedFormat, text: l.feedFormatHelp),
        ],
      ),
    );
  }
}

Future<void> _saveSetting(
  BuildContext context,
  Future<void> Function(SettingsService) save,
) async {
  try {
    await save(context.read<SettingsService>());
  } catch (_) {
    if (context.mounted) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.appChannelsSaveFailed,
        error: true,
      );
    }
  }
}
