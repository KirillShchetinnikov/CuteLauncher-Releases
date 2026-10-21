import 'settings_help.dart';
import 'package:flauncher/widgets/action_notice.dart';

import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/update_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';

class UpdatesPage extends StatelessWidget {
  static const routeName = 'app_updates';
  const UpdatesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<UpdateService>();
    return SettingsPageLayout(
      title: Text(l.appUpdates, style: Theme.of(context).textTheme.titleLarge),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${l.updateInstalled}: ${service.installedVersion}'),
            ),
            if (!service.initialized) const LinearProgressIndicator(),
            if (service.fromPlay)
              SettingsHelp(text: l.updatePlayOnly)
            else ...[
              RoundedSwitchListTile(
                title: Text(l.updatePrereleases),
                value: service.prereleases,
                enabled: !service.busy,
                onChanged: service.setPrereleases,
              ),
              RoundedSwitchListTile(
                title: Text(l.updateAutomatic),
                value: service.automatic,
                onChanged: service.setAutomatic,
              ),
              RoundedSwitchListTile(
                title: Text(l.updateNotifications),
                value: service.notificationsEnabled,
                onChanged: service.setNotificationsEnabled,
              ),
              FocusableSettingsTile(
                autofocus: true,
                title: Text(l.updateCheck),
                leading: const Icon(Icons.refresh),
                onPressed: service.busy || !service.initialized
                    ? null
                    : () async {
                        try {
                          await service.check(force: true, notify: false);
                          if (!context.mounted) return;
                          showActionNotice(
                            context,
                            service.failed
                                ? l.updateCheckFailed
                                : service.release == null
                                ? l.updateNoRelease
                                : '${l.updateAvailable}: ${service.release!.version}',
                            error: service.failed,
                          );
                        } catch (_) {
                          if (context.mounted) {
                            showActionNotice(
                              context,
                              l.updateCheckFailed,
                              error: true,
                            );
                          }
                        }
                      },
              ),
              if (service.release != null) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${l.updateAvailable}: ${service.release!.version}',
                  ),
                ),
                FocusableSettingsTile(
                  title: Text(
                    service.ready ? l.updateInstall : l.updateDownloadInstall,
                  ),
                  leading: const Icon(Icons.system_update_alt),
                  onPressed: service.busy
                      ? null
                      : () async {
                          final task = service.downloadAndInstall();
                          if (service.progress != null) {
                            final close = showActionNotice(
                              context,
                              l.updateDownloadInstall,
                              persistent: true,
                              content: ListenableBuilder(
                                listenable: service,
                                builder: (context, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l.appUpdates}: ${((service.progress ?? 1) * 100).round()}%',
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: service.progress ?? 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                            void onProgress() {
                              if (service.progress == null) {
                                service.removeListener(onProgress);
                                close();
                              }
                            }

                            service.addListener(onProgress);
                            try {
                              await task;
                            } finally {
                              service.removeListener(onProgress);
                              close();
                            }
                          } else {
                            await task;
                          }
                          if (context.mounted &&
                              (service.failed ||
                                  service.installStatus == 'permission')) {
                            showActionNotice(
                              context,
                              service.installStatus == 'permission'
                                  ? l.updatePermission
                                  : updateFailureMessage(l, service),
                              error: service.failed,
                            );
                          }
                        },
                ),
              ] else if (!service.busy && !service.failed && service.checked)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.updateNoRelease),
                ),
              if (service.busy)
                LinearProgressIndicator(value: service.progress),
              if (service.failed)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    updateFailureMessage(l, service),
                  ),
                ),
              if (service.installStatus == 'permission')
                SettingsHelp(text: l.updatePermission),
            ],
          ],
        ),
      ),
    );
  }
}

String updateFailureMessage(AppLocalizations l, UpdateService service) {
  if (service.installStatus == 'invalid') return l.updateIncompatible;
  if (service.installStatus == 'unavailable' || service.ready) {
    return l.updateInstallerFailed;
  }
  return service.checked && service.release != null
      ? l.updateDownloadFailed
      : l.updateCheckFailed;
}
