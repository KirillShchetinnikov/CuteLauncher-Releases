import 'settings_section.dart';
import '../../document_files.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/apps_service.dart';
import '../../providers/night_mode_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/weather_service.dart';

import '../../diagnostics_report.dart';
import '../../diagnostics_store.dart';
import '../../l10n/app_localizations.dart';
import '../../tv_compatibility_report.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

/// A single report retained while diagnostics and its results are open.
class DiagnosticsPage extends StatefulWidget {
  static const routeName = 'diagnostics_panel';
  final Future<Map<String, Object>> Function(bool extended)? collect;
  const DiagnosticsPage({super.key, this.collect});
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final _report = ValueNotifier<Map<String, Object>?>(null);
  @override
  void dispose() {
    _report.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DiagnosticsReportPanel(
    report: _report,
    collect:
        widget.collect ??
        (extended) => collectDiagnostics(
          extended: extended,
          apps: context.read<AppsService?>(),
          settings: context.read<SettingsService?>(),
          nightMode: context.read<NightModeService?>(),
          weather: context.read<WeatherService?>(),
        ),
  );
}

class DiagnosticsReportPanel extends StatefulWidget {
  final ValueNotifier<Map<String, Object>?> report;
  final Future<Map<String, Object>> Function(bool extended) collect;
  const DiagnosticsReportPanel({
    super.key,
    required this.report,
    required this.collect,
  });
  @override
  State<DiagnosticsReportPanel> createState() => _DiagnosticsReportPanelState();
}

class _DiagnosticsReportPanelState extends State<DiagnosticsReportPanel> {
  final _extendedFocus = FocusNode();
  final _stopFocus = FocusNode();
  bool _busy = false;
  bool _creating = false;
  bool _creatingExtended = false;
  bool _exportMenu = false;

  @override
  void initState() {
    super.initState();
    DiagnosticsStore.instance.recording.addListener(_restoreRecordingFocus);
  }

  @override
  void dispose() {
    DiagnosticsStore.instance.recording.removeListener(_restoreRecordingFocus);
    _stopFocus.dispose();
    _extendedFocus.dispose();
    super.dispose();
  }

  void _restoreRecordingFocus() {
    if (_stopFocus.hasFocus && !DiagnosticsStore.instance.isRecording) {
      _extendedFocus.requestFocus();
    }
  }

  Future<void> _create({bool extended = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _creating = true;
      _creatingExtended = extended;
    });
    try {
      final report = await widget.collect(extended);
      if (mounted) {
        widget.report.value = report;
        if (extended) await discardDiagnosticsRecording();
      }
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.diagnosticsCreateFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _creating = false;
          _creatingExtended = false;
        });
      }
    }
  }

  Future<void> _recordExtended(DiagnosticRecordingState state) async {
    if (_busy) return;
    if (state != DiagnosticRecordingState.idle) {
      await _create(extended: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await startDiagnosticsRecording();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.diagnosticsRecordingFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final report = widget.report.value;
    if (_busy || _exportMenu || report == null) return;
    _exportMenu = true;
    final l = AppLocalizations.of(context)!;
    try {
      await showLauncherDialog<void>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(l.diagnosticsExport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.copy),
                title: Text(l.diagnosticsCopyClipboard),
                onPressed: () async {
                  Navigator.pop(dialog);
                  await _performExport(report, copy: true);
                },
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l.diagnosticsSaveDisk),
                onPressed: () async {
                  Navigator.pop(dialog);
                  await _performExport(report, copy: false);
                },
              ),
              SettingsHelp(text: l.diagnosticsSharingNotice),
            ],
          ),
        ),
      );
    } finally {
      _exportMenu = false;
    }
  }

  Future<void> _performExport(
    Map<String, Object> report, {
    required bool copy,
  }) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context)!;
    try {
      if (copy) {
        try {
          await Clipboard.setData(
            ClipboardData(text: DiagnosticsStore.instance.encode(report)),
          );
          if (mounted) showActionNotice(context, l.diagnosticsCopied);
        } catch (_) {
          if (mounted) {
            showActionNotice(context, l.diagnosticsCopyFailed, error: true);
          }
        }
      } else {
        String? saved;
        String? destination;
        try {
          saved = await saveDiagnosticsReport(
            report,
            exporter: (file, {required name}) => DocumentFiles.saveDiagnostics(
              file,
              name: name,
              context: context,
              onSaved: (path) => destination = path,
            ),
          );
        } catch (_) {
          saved = 'failed';
        }
        if (!mounted || saved == null || saved == 'cancelled') return;
        showActionNotice(
          context,
          saved == 'saved'
              ? destination == null
                    ? l.diagnosticsSaved
                    : l.fileBrowserSavedTo(destination!)
              : saved == 'opened'
              ? l.diagnosticsExportOpened
              : l.diagnosticsSaveFailed,
          error: saved != 'saved' && saved != 'opened',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: DiagnosticsStore.instance.recording,
    builder: (context, recording, _) => _buildPage(context, recording),
  );

  Widget _buildPage(BuildContext context, DiagnosticRecordingState recording) {
    final l = AppLocalizations.of(context)!;
    final report = widget.report.value;
    final extendedAction = _creatingExtended
        ? l.diagnosticsCreating
        : switch (recording) {
            DiagnosticRecordingState.idle => l.diagnosticsStartRecording,
            DiagnosticRecordingState.recording => l.diagnosticsFinishRecording,
            DiagnosticRecordingState.stopped => l.diagnosticsCreateExtended,
          };
    return SettingsPageLayout(
      title: Text(l.diagnosticsHubTitle),
      child: ListView(
        children: [
          if (recording == DiagnosticRecordingState.recording)
            SettingsMessage(text: l.diagnosticsRecordingActive),
          if (recording == DiagnosticRecordingState.stopped && !_creating)
            SettingsMessage(text: l.diagnosticsRecordingStopped),
          if (report != null)
            SettingsMessage(
              text: report['reportMode'] == 'extended'
                  ? l.diagnosticsExtendedReady
                  : l.diagnosticsReady,
            ),

          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.note_add_outlined),
            title: Text(
              _creating && !_creatingExtended
                  ? l.diagnosticsCreating
                  : l.diagnosticsCreate,
            ),
            onPressed: _busy ? null : _create,
          ),
          FocusableSettingsTile(
            focusNode: _extendedFocus,
            leading: Icon(
              recording == DiagnosticRecordingState.idle
                  ? Icons.fiber_manual_record_outlined
                  : Icons.description_outlined,
            ),
            title: Text(extendedAction),
            onPressed: _busy ? null : () => _recordExtended(recording),
          ),
          if (recording == DiagnosticRecordingState.recording) ...[
            FocusableSettingsTile(
              focusNode: _stopFocus,
              leading: const Icon(Icons.stop_circle_outlined),
              title: Text(l.diagnosticsStopRecording),
              busy: _busy,
              onPressed: DiagnosticsStore.instance.finishRecording,
            ),

          ],
          SettingsSection(title: l.tvCompatibilityResults, children: [
          FocusableSettingsTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(l.tvCompatibilityResults),
            onPressed: _busy || report?['compatibility'] is! Map
                ? null
                : () => Navigator.of(context).push(
                    SettingsRoute<void>(
                      builder: (_) => CompatibilityResultsPage(report: report!),
                    ),
                  ),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.diagnosticsClear),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await clearDiagnostics();
                    if (!mounted || !context.mounted) return;
                    setState(() {
                      _busy = false;
                      widget.report.value = null;
                    });
                    showActionNotice(
                      context,
                      '${l.diagnosticsClear}: ${l.actionCompleted}',
                    );
                  },
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.diagnosticsExport),
            onPressed: _busy || report == null ? null : _export,
          ),
          ]),
          SettingsHelp(
            text: '${l.diagnosticsHint}\n\n${l.diagnosticsSharingNotice}',
          ),
        ],
      ),
    );
  }
}

String compatibilityCheckLabel(AppLocalizations l, String id) => switch (id) {
  'androidTv' => l.compatibilityAndroidTv,
  'androidVersion' => l.compatibilityAndroidVersion,
  'homeRegistered' => l.compatibilityHomeRegistered,
  'defaultHome' => l.compatibilityDefaultHome,
  'homeSelection' => l.compatibilityHomeSelection,
  'overlay' => l.compatibilityOverlay,
  'notifications' => l.compatibilityNotifications,
  'notificationListener' => l.compatibilityNotificationListener,
  'accessibility' => l.compatibilityAccessibility,
  'writeSettings' => l.compatibilityWriteSettings,
  'usageStats' => l.compatibilityUsageStats,
  'watchNext' => l.compatibilityWatchNext,
  'tvInputs' => l.compatibilityTvInputs,
  'documentExport' => l.compatibilityDocumentExport,
  'screensaverSelection' => l.compatibilityScreensaverSelection,
  _ => l.compatibilityUnknown,
};
String compatibilityStatusLabel(AppLocalizations l, dynamic status) =>
    switch (status) {
      'available' => l.compatibilityAvailable,
      'notGranted' => l.compatibilityNotGranted,
      'notConfigured' => l.compatibilityNotConfigured,
      'restricted' => l.compatibilityRestricted,
      'unsupported' => l.compatibilityUnsupported,
      _ => l.compatibilityUnknown,
    };

class CompatibilityResultsPage extends StatelessWidget {
  final Map<String, Object> report;
  const CompatibilityResultsPage({super.key, required this.report});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final identity = report['device'] as Map? ?? {};
    final checks = (report['compatibility'] as Map?)?['checks'] as Map? ?? {};
    final app = report['app'] as Map? ?? {};
    return SettingsPageLayout(
      title: Text(l.tvCompatibilityResults),
      child: Builder(
        builder: (context) {
          final scroll = PrimaryScrollController.of(context);
          return Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final key = event.logicalKey;
              if (key != LogicalKeyboardKey.arrowDown &&
                  key != LogicalKeyboardKey.arrowUp) {
                return KeyEventResult.ignored;
              }
              if (scroll.hasClients) {
                scroll.animateTo(
                  (scroll.offset +
                          (key == LogicalKeyboardKey.arrowDown ? 100 : -100))
                      .clamp(0, scroll.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                );
              }
              return KeyEventResult.handled;
            },
            child: SingleChildScrollView(
              key: const ValueKey('compatibility_results_scroll'),
              controller: scroll,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.settingsHelpScroll),
                    Text(
                      '${l.compatibilityReportDate}: ${report['capturedAt'] ?? '—'}\n'
                      '${l.compatibilityLauncherVersion}: ${app['version'] ?? '—'}',
                    ),
                    Text(
                      '${identity['manufacturer'] ?? '—'} ${identity['model'] ?? '—'}\nAndroid ${identity['androidRelease'] ?? '—'} / API ${(report['system'] as Map?)?['androidApi'] ?? '—'}\n${identity['abis'] ?? '—'}\n${identity['fingerprint'] ?? '—'}',
                    ),
                    if ((report['compatibility'] as Map?)?['status'] !=
                        'complete')
                      Text(
                        '${l.tvCompatibilityResults}: ${l.compatibilityUnknown}',
                      ),
                    const Divider(),
                    for (final id in tvCompatibilityChecks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${compatibilityCheckLabel(l, id)}: ${compatibilityStatusLabel(l, checks[id])}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
