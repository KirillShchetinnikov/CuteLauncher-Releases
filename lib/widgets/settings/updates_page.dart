import 'support_developer_tile.dart';
import 'settings_section.dart';
import 'package:flauncher/widgets/action_notice.dart';

import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/update_service.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_scroll_behavior.dart';

class UpdatesPage extends StatelessWidget {
  static const routeName = 'app_updates';
  const UpdatesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<UpdateService>();
    final release = service.release;
    return SettingsPageLayout(
      title: Text(l.appUpdates, style: Theme.of(context).textTheme.titleLarge),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(title: l.supportProjectGroup, children: const [SupportDeveloperTile()]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${l.updateInstalled}: ${displayAppVersion(service.installedVersion)}',
              ),
            ),
            SizedBox(
              child: !service.initialized
                  ? const LinearProgressIndicator()
                  : null,
            ),
            if (service.fromPlay)
              Text(l.updatePlayOnly)
            else ...[
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
                                : '${l.updateAvailable}: ${displayAppVersion(service.release!.version)}',
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
              if (release != null) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${l.updateAvailable}: ${displayAppVersion(release.version)}',
                  ),
                ),
                FocusableSettingsTile(
                  title: Text(l.updateWhatsNew),
                  leading: const Icon(Icons.notes_rounded),
                  onPressed: () => showLauncherDialog<void>(
                    context: context,
                    builder: (_) =>
                        _ReleaseNotesDialog(release: release, service: service),
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
                  child: Text(updateFailureMessage(l, service)),
                ),
              if (service.installStatus == 'permission')
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l.updatePermission,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SettingsSection(title: l.settings, children: [
              RoundedSwitchListTile(
                title: Text(l.updatePrereleases),
                value: service.prereleases,
                busy: service.busy,
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
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReleaseNotesDialog extends StatefulWidget {
  final AppRelease release;
  final UpdateService service;

  const _ReleaseNotesDialog({required this.release, required this.service});

  @override
  State<_ReleaseNotesDialog> createState() => _ReleaseNotesDialogState();
}

class _ReleaseNotesDialogState extends State<_ReleaseNotesDialog> {
  final _scroll = ScrollController();
  String? _language;
  Future<String?>? _notes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language == _language) return;
    _language = language;
    _notes = widget.service.releaseNotes(widget.release.version, language);
  }

  void _scrollBy(double direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    position.jumpTo(
      (position.pixels + direction * position.viewportDimension * .35).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _scrollBy(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _scrollBy(1),
      },
      child: LauncherAlertDialog(
        title: Text(
          '${l.updateWhatsNew} · ${displayAppVersion(widget.release.version)}',
        ),
        scrollContent: false,
        content: SizedBox(
          width: 400,
          child: FutureBuilder<String?>(
            future: _notes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              final notes = snapshot.data;
              return SettingsScrollbar(
                controller: _scroll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsetsDirectional.only(end: 14),
                  child: Text(
                    notes == null
                        ? l.updateNotesUnavailable
                        : notes
                              .replaceAllMapped(
                                RegExp(r'\*\*([^*\n]+)\*\*'),
                                (match) => match.group(1)!,
                              )
                              .replaceAll(
                                RegExp(r'^- ', multiLine: true),
                                '• ',
                              ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}

String updateFailureMessage(AppLocalizations l, UpdateService service) {
  switch (service.installStatus) {
    case 'invalid_package':
      return l.updateWrongPackage;
    case 'invalid_version':
      return l.updateNotNewer;
    case 'invalid_signers':
      return l.updateSignersUnavailable;
    case 'invalid_signature':
      return l.updateSignatureMismatch;
    case 'invalid_file':
      return l.updateInvalidFile;
    case 'invalid_verification':
      return l.updateVerificationFailed;
  }
  if (service.installStatus == 'invalid') return l.updateIncompatible;
  if (service.installStatus == 'unavailable' || service.ready) {
    return l.updateInstallerFailed;
  }
  return service.checked && service.release != null
      ? l.updateDownloadFailed
      : l.updateCheckFailed;
}
