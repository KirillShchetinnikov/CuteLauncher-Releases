import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/online_wallpaper_service.dart';
import '../providers/screensaver_service.dart';
import '../providers/settings_service.dart';
import '../providers/slideshow_service.dart';
import '../providers/video_folder_service.dart';
import '../quick_actions.dart';
import 'action_notice.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'quick_action_presentation.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/quick_actions_settings_page.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'side_panel_dialog.dart';
import 'tv_power_action.dart';

class QuickActionsMenu extends StatefulWidget {
  final Rect anchor;
  const QuickActionsMenu({super.key, required this.anchor});

  @override
  State<QuickActionsMenu> createState() => _QuickActionsMenuState();
}

class _QuickActionsMenuState extends State<QuickActionsMenu> {
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;
  bool _busy = false;

  @override
  void dispose() {
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    if (_busy || _settingsOpen) return;
    setState(() => _settingsOpen = true);
    try {
      await showLauncherDialog<void>(
        context: context,
        parentPanelHidden: true,
        styleDialog: false,
        barrierColor: Colors.transparent,
        builder: (_) => const SettingsPanel(
          initialRoute: QuickActionsSettingsPage.routeName,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _settingsOpen = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _settingsNode.requestFocus();
        });
      }
    }
  }

  Future<void> _run(QuickAction action) async {
    if (_busy || _settingsOpen) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final operation = switch (action) {
        QuickAction.sleep => TvPowerAction.sleep.confirmAndSend(context),
        QuickAction.shutdown => TvPowerAction.shutdown.confirmAndSend(context),
        QuickAction.reboot => TvPowerAction.reboot.confirmAndSend(context),
        QuickAction.screensaver => _startScreensaver(l),
        QuickAction.wallpaper => _changeWallpaper(l),
      };
      final completed = await operation;
      if (completed && mounted && ModalRoute.isCurrentOf(context) == true) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _startScreensaver(AppLocalizations l) async {
    final service = context.read<ScreensaverService?>();
    final started = await service?.startAmbientMode() == true;
    if (!started && mounted) {
      showActionNotice(
        context,
        l.quickActionsScreensaverUnavailable,
        error: true,
      );
    }
    return started;
  }

  Future<bool> _changeWallpaper(AppLocalizations l) async {
    final settings = context.read<SettingsService>();
    final source = settings.backgroundSource;
    bool? changed;
    try {
      switch (source) {
        case 'slideshow':
          final service = context.read<SlideshowService?>();
          if (service != null && service.folder.isNotEmpty) {
            final version = service.version;
            await service.advance();
            changed = service.version != version && !service.failed;
          }
        case videoFolderSource:
          final service = context.read<VideoFolderService?>();
          if (service != null && service.folder.isNotEmpty) {
            final previous = service.clip;
            await service.next();
            changed =
                service.clip != null && !identical(previous, service.clip);
          }
        case 'online':
          final service = context.read<OnlineWallpaperService?>();
          if (service != null &&
              service.configuration.enabled &&
              service.configuration.validUrl) {
            final version = service.version;
            await service.refresh(force: true);
            changed = service.version != version && !service.failed;
          }
      }
    } catch (_) {
      changed = false;
    }
    if (!mounted || settings.backgroundSource != source) return false;
    if (changed == true) return true;
    showActionNotice(
      context,
      changed == null
          ? l.quickActionsWallpaperUnavailable
          : l.quickActionsWallpaperFailed,
      error: changed == false,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      final actions = context.watch<SettingsService>().quickActions;
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
                width: 380,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MenuHeader(
                          title: Text(l.quickActionsTitle),
                          actions: [
                            MenuHeaderAction(
                              focusNode: _settingsNode,
                              autofocus: actions.isEmpty,
                              tooltip: l.quickActionsSettings,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: _busy ? null : _openSettings,
                            ),
                          ],
                        ),
                        const Divider(),
                        if (actions.isEmpty) Text(l.quickActionsEmpty),
                        for (final action in actions)
                          FocusableSettingsTile(
                            key: ValueKey(action),
                            title: Text(action.label(l)),
                            leading: Icon(action.icon),
                            autofocus: action == actions.first,
                            scrollOnFocus: action != actions.first,
                            busy: _busy,
                            showActionChevron: false,
                            onPressed: () => _run(action),
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
    },
  );
}
