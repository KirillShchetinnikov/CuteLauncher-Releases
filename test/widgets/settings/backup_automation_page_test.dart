import 'package:flauncher/backup_schedule.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/widgets/settings/backup_sync_groups_page.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/automatic_backup_service.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/automatic_backup_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_route.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _Automatic extends ChangeNotifier implements AutomaticBackupService {
  @override
  bool busy = false, failed = false, enabled = false;
  @override
  int keepCount = 5;
  @override
  BackupSchedule schedule = const BackupSchedule();
  @override
  List<AutomaticBackupEntry> get entries => [];
  @override
  Future<void> setSchedule(BackupSchedule value) async {
    schedule = value;
    notifyListeners();
  }

  @override
  Future<void> setKeepCount(int value) async {
    keepCount = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Automation extends ChangeNotifier implements BackupAutomationService {
  final disabledGroups = <BackupSyncGroup>{};
  @override
  bool syncGroupEnabled(BackupSyncGroup group) =>
      !disabledGroups.contains(group);
  @override
  Future<void> setSyncGroupEnabled(BackupSyncGroup group, bool enabled) async {
    if (enabled) {
      disabledGroups.remove(group);
    } else {
      disabledGroups.add(group);
    }
    notifyListeners();
  }

  @override
  bool busy = false,
      failed = false,
      shared = false,
      enabled = false,
      configured = true;
  @override
  BackupDestination destination = BackupDestination.local;
  @override
  BackupMode mode = BackupMode.backup;
  @override
  DateTime? lastSuccess;
  @override
  int syncMinutes = 15;
  @override
  String get scope => 'shared';
  @override
  String? get localFolder => null;
  int imports = 0, deletes = 0, creates = 0;
  @override
  Future<void> deleteCopy(RemoteBackupFile copy) async {
    deletes++;
  }

  @override
  Future<void> configure({
    BackupDestination? destination,
    BackupMode? mode,
    bool? shared,
    bool? enabled,
    int? syncMinutes,
  }) async {
    this.destination = destination ?? this.destination;
    this.mode = mode ?? this.mode;
    this.shared = shared ?? this.shared;
    this.enabled = enabled ?? this.enabled;
    this.syncMinutes = syncMinutes ?? this.syncMinutes;
    notifyListeners();
  }

  @override
  Future<void> importLatest({RemoteBackupFile? selected}) async {
    imports++;
  }

  @override
  Future<List<RemoteBackupFile>> availableCopies() async => [
    RemoteBackupFile(
      'cute-backup-shared-${'a' * 32}-100-${'b' * 16}.json',
      'test',
    ),
  ];

  @override
  Future<bool> run({bool manual = false, bool exportOnly = false}) async =>
      (++creates) > 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'automatic backups choose storage, schedule and sync mode; import requires confirmation $language',
      (tester) async {
        await initializeDateFormatting(language);
        final local = _Automatic(), automation = _Automation();
        final cloud = CloudBackupService(), drive = DriveBackupService();
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AutomaticBackupService>.value(
                value: local,
              ),
              ChangeNotifierProvider<BackupAutomationService>.value(
                value: automation,
              ),
              ChangeNotifierProvider<CloudBackupService>.value(value: cloud),
              ChangeNotifierProvider<DriveBackupService>.value(value: drive),
            ],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: SizedBox(
                  width: 340,
                  child: Navigator(
                    onGenerateRoute: (_) => SettingsRoute(
                      builder: (_) => const AutomaticBackupPage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(AutomaticBackupPage)),
        )!;
        Future<void> activate(String label) async {
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          final tile = find.widgetWithText(FocusableSettingsTile, label);
          await tester.scrollUntilVisible(
            tile,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tap(tile);
          await tester.pumpAndSettle();
        }

        Future<void> back() async {
          Navigator.of(tester.element(find.byType(BackupOptionsPage))).pop();
          await tester.pumpAndSettle();
        }

        expect(find.text(l.backupNever), findsOneWidget);
        expect(find.text(l.backupLastCreated), findsOneWidget);
        expect(find.byType(RoundedSwitchListTile), findsNothing);
        await activate(l.backupOptions);
        expect(find.text(l.automaticBackupsKeep), findsOneWidget);
        expect(find.text(l.backupScope), findsOneWidget);
        expect(
          tester
              .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
              .enabled,
          true,
        );
        await activate(l.backupFrequency);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupWeekly),
        );
        await tester.pumpAndSettle();
        expect(local.schedule.frequency, BackupFrequency.weekly);
        await back();
        await activate(l.backupStorage);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, 'WebDAV / Nextcloud'),
        );
        await tester.pumpAndSettle();
        automation.configured = false;
        automation.notifyListeners();
        await tester.pumpAndSettle();
        final management = find.widgetWithText(
          FocusableSettingsTile,
          l.backupManagement,
        );
        await tester.scrollUntilVisible(management, 100);
        await tester.ensureVisible(management);
        await tester.pumpAndSettle();
        expect(tester.widget<FocusableSettingsTile>(management).enabled, false);
        expect(find.text(l.backupCreateNow), findsNothing);
        expect(find.text(l.exportBackup), findsNothing);
        expect(find.text(l.importBackup), findsNothing);
        automation.configured = true;
        automation.notifyListeners();
        await tester.pumpAndSettle();
        await activate(l.backupOptions);
        await activate(l.backupScope);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupShared),
        );
        await tester.pumpAndSettle();
        expect(automation.shared, true);
        final keep = find.widgetWithText(
          SettingsValueStepper,
          l.automaticBackupsKeep,
        );
        await tester.ensureVisible(keep);
        await tester.pumpAndSettle();
        expect(tester.widget<SettingsValueStepper>(keep).value, 5);
        await activate(l.backupWeekday);
        await tester.tap(
          find
              .descendant(
                of: find.byType(SimpleDialog),
                matching: find.byType(FocusableSettingsTile),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await back();
        await activate(l.backupMode);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupSyncMode),
        );
        await tester.pumpAndSettle();
        await activate(l.backupSyncOptions);
        expect(find.text(l.backupSyncScope), findsOneWidget);
        expect(find.text(l.backupShared), findsOneWidget);
        expect(find.text(l.automaticBackupsKeep), findsNothing);
        expect(find.text(l.backupSyncHelp), findsNothing);
        expect(find.text(l.backupFrequency), findsNothing);
        await activate(l.backupSyncSettings);
        expect(find.byType(BackupSyncGroupsPage), findsOneWidget);
        final firstHeading = find.byKey(const ValueKey(BackupSyncSection.home));
        expect(firstHeading, findsOneWidget);
        expect(
          find.descendant(of: firstHeading, matching: find.byType(Focus)),
          findsNothing,
        );
        for (final group in BackupSyncGroup.values) {
          final toggle = find.byKey(ValueKey(group));
          await tester.scrollUntilVisible(
            toggle,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          expect(tester.widget<RoundedSwitchListTile>(toggle).value, true);
          expect(tester.takeException(), isNull);
        }
        final weather = find.byKey(
          const ValueKey(BackupSyncGroup.weatherDisplay),
        );
        await tester.scrollUntilVisible(
          weather,
          -100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(weather);
        await tester.pumpAndSettle();
        await tester.tap(weather);
        await tester.pumpAndSettle();
        expect(tester.widget<RoundedSwitchListTile>(weather).value, false);
        expect(
          automation.syncGroupEnabled(BackupSyncGroup.weatherDisplay),
          false,
        );
        expect(
          automation.syncGroupEnabled(BackupSyncGroup.weatherSource),
          true,
        );
        automation.busy = true;
        automation.notifyListeners();
        await tester.pump();
        expect(tester.widget<RoundedSwitchListTile>(weather).enabled, false);
        automation.busy = false;
        automation.notifyListeners();
        Navigator.of(tester.element(find.byType(BackupSyncGroupsPage))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(BackupOptionsPage), findsOneWidget);
        await back();
        await activate(l.backupManagement);
        expect(find.text(l.backupRestoreCopy), findsNothing);
        expect(find.text(l.delete), findsNothing);
        final copy = find.byKey(
          ValueKey('cute-backup-shared-${'a' * 32}-100-${'b' * 16}.json'),
        );
        expect(copy, findsOneWidget);
        Future<void> openCopy() async {
          await tester.ensureVisible(copy);
          await tester.pumpAndSettle();
          await tester.tap(copy);
          await tester.pumpAndSettle();
          expect(find.byType(SimpleDialog), findsOneWidget);
        }

        await openCopy();
        await activate(l.backupRestoreCopy);
        expect(find.text(l.backupCloudImportConfirm), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, l.cancel));
        await tester.pumpAndSettle();
        expect(automation.imports, 0);
        await openCopy();
        await activate(l.backupRestoreCopy);
        await tester.tap(find.widgetWithText(TextButton, l.importAction));
        await tester.pumpAndSettle();
        expect(automation.imports, 1);
        await openCopy();
        await activate(l.delete);
        expect(find.text(l.backupDeleteConfirm), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, l.delete));
        await tester.pumpAndSettle();
        expect(automation.deletes, 1);
        await activate(l.backupCreateNow);
        expect(automation.creates, 1);
        expect(tester.takeException(), isNull);
        for (final element in find.byType(RichText).evaluate()) {
          expect(
            (element.renderObject as RenderParagraph).didExceedMaxLines,
            false,
          );
        }
        await tester.pumpWidget(const SizedBox());
        automation.dispose();
        local.dispose();
        cloud.dispose();
        drive.dispose();
      },
    );
  }
}
