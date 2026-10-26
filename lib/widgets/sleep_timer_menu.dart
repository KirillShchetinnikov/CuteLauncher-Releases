import '../providers/settings_service.dart';
import '../theme/launcher_style.dart';
import '../sleep_timer_configuration.dart';
import 'menu_header_action.dart';
import 'sleep_timer_label.dart';
import 'settings/settings_panel.dart';
import 'settings/sleep_timer_settings_page.dart';

import 'package:flutter/material.dart';

import 'action_notice.dart';

import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/sleep_timer_service.dart';
import 'menu_header.dart';
import 'side_panel_dialog.dart';
import 'settings/settings_panel_style.dart';
import 'launcher_dialog.dart';
import 'settings/focusable_settings_tile.dart';

class SleepTimerMenu extends StatefulWidget {
  final Rect anchor;
  const SleepTimerMenu({super.key, required this.anchor});

  @override
  State<SleepTimerMenu> createState() => _SleepTimerMenuState();
}

class _SleepTimerMenuState extends State<SleepTimerMenu> {
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;
  @override
  void dispose() {
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    if (context.read<SleepTimerService>().busy) return;
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: SleepTimerSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  String _presetKey(SleepTimerPreset preset) {
    if (preset.id == 'default_30') return 'sleep_timer_30_seconds';
    for (final minutes in defaultSleepTimerMinutes) {
      if (preset.id == 'default_${minutes * 60}') return 'sleep_timer_$minutes';
    }
    return 'sleep_timer_custom_${preset.id}';
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(builder: _buildMenu);

  Widget _buildMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final timer = context.watch<SleepTimerService>();
    final configuration =
        context.watch<SettingsService?>()?.sleepTimerConfiguration ??
        SleepTimerConfiguration();
    final titlePainter = TextPainter(
      text: TextSpan(
        text: l.sleepTimer,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    )..layout();
    // Reserve the panel border/padding, body/header insets and settings button.
    // SidePanelDialog still limits this width to the available screen space.
    final menuWidth =
        (titlePainter.width +
                LauncherStyle.of(context).panelPadding * 2 +
                2 +
                32 +
                36)
            .clamp(380.0, double.infinity);
    titlePainter.dispose();
    return ExcludeFocus(
      excluding: _settingsOpen,
      child: Offstage(
        offstage: _settingsOpen,
        child: Stack(
          children: [
            const Positioned.fill(child: LauncherPanelBackdrop()),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            SidePanelDialog(
              anchor: widget.anchor,
              width: menuWidth,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MenuHeader(
                          title: Text(l.sleepTimer),
                          actions: [
                            MenuHeaderAction(
                              focusNode: _settingsNode,
                              tooltip: l.sleepTimerSettings,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: _openSettings,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      if (timer.active)
                        Text(
                          sleepTimerActiveLabel(context, timer, configuration),
                        ),
                      if (timer.busy)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: LinearProgressIndicator(),
                        ),
                      if (timer.error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            timer.error == 'exact'
                                ? l.sleepTimerExactRequired
                                : timer.error == 'access'
                                ? l.sleepTimerAccessRequired
                                : l.sleepTimerFailed,
                          ),
                        ),
                      if (!timer.exactAllowed || timer.error == 'exact')
                        FocusableSettingsTile(
                          title: Text(l.sleepTimerAllowExact),
                          onPressed: () async {
                            if (!await timer.requestExact() &&
                                context.mounted) {
                              showActionNotice(
                                context,
                                l.sleepTimerExactRequired,
                                error: true,
                              );
                            }
                          },
                        ),
                      FocusableSettingsTile(
                        key: const ValueKey('sleep_timer_0'),
                        autofocus: true,
                        enabled: !timer.busy,
                        title: Text(l.cancel),
                        onPressed: () async {
                          if (await timer.select(0) &&
                              context.mounted &&
                              configuration.closeAfterSelection) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      for (final preset in configuration.presets.where(
                        (p) => p.visible,
                      ))
                        FocusableSettingsTile(
                          key: ValueKey(_presetKey(preset)),
                          enabled: !timer.busy,
                          title: Text(sleepTimerPresetLabel(l, preset.seconds)),
                          onPressed: () async {
                            final success = await timer.selectSeconds(
                              preset.seconds,
                            );
                            if (success &&
                                context.mounted &&
                                configuration.closeAfterSelection) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
