import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';

import '../bridge_result.dart';
import '../l10n/app_localizations.dart';
import '../theme/launcher_style.dart';
import 'side_panel_dialog.dart';
import 'settings/settings_panel_style.dart';
import 'settings/settings_menu_layout.dart';
import 'launcher_dialog.dart';
import 'action_notice.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/settings_route.dart';
import 'settings/local_file_browser.dart';

/// Shared entry point for every interactive document operation.
class FileSelection {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  static bool _selecting = false;

  static Future<bool> requestStorage(BuildContext context, {required bool write}) async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestFileStorage', {'write': write});
      if (!context.mounted) return false;
      if (granted == true) return true;
      showActionNotice(context, AppLocalizations.of(context)!.slideshowStoragePermission, error: true);
    } on BridgeException catch (error) {
      if (error.code != 'storage_settings_unavailable') rethrow;
      if (context.mounted) {
        showActionNotice(context, AppLocalizations.of(context)!.fileStorageSettingsUnavailable, error: true);
      }
    }
    return false;
  }

  static Future<T?> select<T>(
    BuildContext context,
    String operation, {
    Map<String, Object?> arguments = const {},
    String? initialPath,
    ValueChanged<String>? onSaved,
  }) async {
    if (_selecting) return null;
    _selecting = true;
    try {
      final available = await _channel.invokeMethod<bool>(
        'filePickerAvailable',
        {'operation': operation},
      );
      if (!context.mounted) return null;
      if (available == true) {
        final l = AppLocalizations.of(context)!;
        final system = await showLauncherDialog<bool>(
          context: context,
          builder: (dialog) => LauncherAlertDialog(
            title: Text(l.filePickerChoose),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  title: Text(l.filePickerSystem),
                  leading: const Icon(Icons.folder_shared_outlined),
                  onPressed: () => Navigator.pop(dialog, true),
                ),
                FocusableSettingsTile(
                  title: Text(l.filePickerBuiltIn),
                  leading: const Icon(Icons.folder_outlined),
                  onPressed: () => Navigator.pop(dialog, false),
                ),
              ],
            ),
          ),
        );
        if (system == null || !context.mounted) return null;
        if (system) {
          try {
            return await _channel.invokeMethod<T>(operation, arguments);
          } on BridgeException catch (error) {
            if (error.status != BridgeStatus.unsupported) rethrow;
            // The handler may have disappeared since the availability query.
            if (!context.mounted) return null;
          }
        }
      }
      final save = operation.startsWith('save');
      final folder =
          operation == 'pickWallpaperFolder' || operation == 'pickBackupFolder';
      final kind = save || folder
          ? FileBrowserKind.folder
          : switch (operation) {
              'pickImageDocument' => FileBrowserKind.image,
              'pickWallpaperDocument' => FileBrowserKind.media,
              'pickWebhookDocument' ||
              'pickCleanerDocument' ||
              'pickCleanerListDocument' => FileBrowserKind.text,
              _ => FileBrowserKind.document,
            };
      final granted = await requestStorage(context, write: save || operation == 'pickBackupFolder');
      if (!context.mounted) return null;
      if (!granted) return null;
      Widget browser(BuildContext _) => LocalFileBrowser(
        initialPath: initialPath,
        kind: kind,
        saveName: save ? arguments['name'] as String? : null,
        title: switch (operation) {
          'saveBackupDocument' => AppLocalizations.of(context)!.exportBackup,
          'saveDiagnosticsDocument' => AppLocalizations.of(
            context,
          )!.diagnosticsExport,
          'pickBackupDocument' => AppLocalizations.of(context)!.importBackup,
          'pickImageDocument' => AppLocalizations.of(context)!.openImage,
          'pickWallpaperDocument' => AppLocalizations.of(context)!.wallpaper,
          'pickWebhookDocument' => AppLocalizations.of(
            context,
          )!.remoteMappingImport,
          'pickCleanerListDocument' => AppLocalizations.of(
            context,
          )!.cleanerLists,
          _ => null,
        },
        formatHint: switch (operation) {
          'saveBackupDocument' ||
          'saveDiagnosticsDocument' ||
          'pickBackupDocument' => 'JSON',
          'pickWebhookDocument' ||
          'pickCleanerDocument' ||
          'pickCleanerListDocument' => 'TXT · JSON',
          'pickImageDocument' => 'JPG · JPEG · PNG · WEBP · GIF · BMP',
          'pickWallpaperDocument' => 'JPG · JPEG · PNG · WEBP · GIF · BMP · MP4 · M4V · MKV · WEBM · MOV · AVI · 3GP',
          _ => null,
        },
      );
      final sourceSide = SettingsMenuLayout.isOnRight(context);
      final navigator = Navigator.of(context);
      if (!navigator.mounted) return null;
      final inSettings = SettingsMenuLayout.maybeOf(navigator.context) != null;
      final selected = inSettings
          ? await navigator.push<String>(SettingsRoute(builder: browser))
          : await showLauncherDialog<String>(
              context: context,
              barrierDismissible: false,
              styleDialog: false,
              builder: (_) => SettingsPanelStyle(
                builder: (context) => SettingsMenuLayout(
                  onRight:
                      context.watch<SettingsService?>()?.settingsMenuOnRight ??
                      sourceSide,
                  child: SidePanelDialog(
                    width: LauncherStyle.of(context).settingsWidth,
                    child: Builder(builder: browser),
                  ),
                ),
              ),
            );
      if (selected == null || !context.mounted) return null;
      if (folder) {
        if (operation == 'pickBackupFolder') {
          await _channel.invokeMethod<Object>('backupFolderOperation', {
            'operation': 'verify',
            'uri': selected,
          });
        }
        return context.mounted ? selected as T : null;
      }
      final result = await _channel.invokeMethod<Object>(
        'localDocumentOperation',
        {
          'operation': operation,
          'selected': selected,
          'source': arguments['path'],
          'name': arguments['name'],
        },
      );
      if (save && result is Map && result['path'] is String) {
        onSaved?.call(result['path'] as String);
        return result['result'] as T?;
      }
      return result as T?;
    } finally {
      _selecting = false;
    }
  }
}
