import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/actions.dart';
import 'package:flauncher/widgets/settings/backup_feature_page.dart';
import 'package:flauncher/widgets/settings/settings_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/backup_data_protection.dart';
import 'package:flauncher/backup_schedule.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/automatic_backup_service.dart';
import 'package:flauncher/providers/backup_accounts.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/widgets/settings/backup_setup_wizard.dart';
import 'package:flauncher/widgets/settings/backup_sync_groups_page.dart';
import 'package:flauncher/widgets/settings/settings_checkbox_tile.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/smb_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/local_backup_page.dart';

class _Cloud extends CloudBackupService {
  @override
  Future<void> refreshAccount() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Drive extends DriveBackupService {
  @override
  Future<void> refreshAccount() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Smb extends SmbBackupService {
  @override
  Future<void> refreshAccount() async {}
}

class _Protection extends BackupDataProtection {
  _Protection() : super('synchronization');
  @override
  Future<bool> configured() async => false;
  @override
  Future<void> setPassword(String password) async {}
}

class _Local extends ChangeNotifier implements AutomaticBackupService {
  @override
  BackupSchedule schedule = const BackupSchedule();
  @override
  int keepCount = 5;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Setup extends ChangeNotifier implements BackupAutomationService {
  @override
  bool get cleanupFailed => false;
  @override
  DateTime? get lastSuccess => null;
  @override
  final webdav = _Cloud();
  @override
  final drive = _Drive();
  @override
  final smb = _Smb();
  @override
  DriveBackupService get yandex => drive;
  @override
  String accountId(BackupDestination type) => 'default';
  @override
  String? get localFolder => null;
  @override
  void dispose() {
    webdav.dispose();
    smb.dispose();
    drive.dispose();
    super.dispose();
  }

  @override
  BackupMode mode = BackupMode.synchronization;
  @override
  bool busy = false, configured = true, shared = true, enabled = false;
  @override
  BackupDestination destination = BackupDestination.local;
  @override
  int syncMinutes = 15;
  @override
  final protection = _Protection();
  @override
  BackupAccounts? accounts;
  final disabled = <BackupSyncGroup>{};
  int runs = 0;
  bool completed = false;
  final remote = DateTime(2026, 11, 12);
  @override
  bool syncGroupEnabled(BackupSyncGroup g) => !disabled.contains(g);
  @override
  Future<void> setSyncGroups(Set<BackupSyncGroup> values) async {
    disabled
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  @override
  Future<void> setSyncGroupEnabled(BackupSyncGroup g, bool value) async {
    value ? disabled.remove(g) : disabled.add(g);
    notifyListeners();
  }

  @override
  Future<DateTime?> inspectSynchronization() async => remote;
  @override
  Future<void> configure({
    BackupDestination? destination,
    BackupMode? mode,
    bool? shared,
    bool? enabled,
    int? syncMinutes,
  }) async {
    if (enabled != null) this.enabled = enabled;
    notifyListeners();
  }

  @override
  Future<bool> resumeSynchronization(
    ChooseBackupSyncResume choose, {
    bool enable = true,
  }) async {
    final choice = await choose(null, remote);
    if (choice == null) return false;
    runs++;
    enabled = true;
    return true;
  }

  @override
  Future<void> completeSetup() async {
    completed = true;
  }

  @override
  Future<bool> run({bool manual = false, bool exportOnly = false}) async {
    runs++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  void checkStyles(WidgetTester tester) {
    for (final element in find.byType(Text).evaluate()) {
      final style = DefaultTextStyle.of(element).style;
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(style.fontSize ?? 14, lessThan(40));
    }
    final next = find.descendant(
      of: find.byKey(const ValueKey('backupSetupNext')),
      matching: find.byType(TextButton),
    );
    if (next.evaluate().isNotEmpty) {
      final button = tester.widget<TextButton>(next);
      final colors = Theme.of(tester.element(next)).colorScheme;
      expect(button.style!.backgroundColor!.resolve({}), colors.primary);
      expect(button.style!.foregroundColor!.resolve({}), colors.onPrimary);
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.focused}),
        colors.primary,
      );
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        isNot(colors.primary),
      );
    }
  }

  for (final mode in BackupMode.values) {
    testWidgets('$mode grouped settings restore remote focus after subpages', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _Setup()..mode = mode;
      final local = _Local();
      addTearDown(service.dispose);
      addTearDown(local.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AutomaticBackupService>.value(
          value: local,
          child: MaterialApp(
            builder: (_, child) => Scaffold(body: child),
            shortcuts: {
              ...WidgetsApp.defaultShortcuts,
              const SingleActivator(LogicalKeyboardKey.escape):
                  const BackIntent(),
            },
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: backupServiceScope(service, const BackupFeaturePage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSection), findsNWidgets(4));
      final l = AppLocalizations.of(
        tester.element(find.byType(BackupFeaturePage)),
      )!;
      for (final label in [
        l.backupStorage,
        l.backupPassword,
        mode == BackupMode.backup ? l.backupOptions : l.backupSyncOptions,
      ]) {
        final row = find.text(label).last;
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.byType(BackupFeaturePage), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(BackupFeaturePage), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(BackupFeaturePage), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
    for (final destination in BackupDestination.values) {
      testWidgets('$mode opens styled $destination connection from wizard', (
        tester,
      ) async {
        final service = _Setup()
          ..mode = mode
          ..destination = destination;
        final local = _Local();
        var escapedBack = 0;
        addTearDown(service.dispose);
        addTearDown(local.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BackupAutomationService>.value(
                value: service,
              ),
              ChangeNotifierProvider<AutomaticBackupService>.value(
                value: local,
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
                },
                child: Actions(
                  actions: {
                    BackIntent: CallbackAction<BackIntent>(
                      onInvoke: (_) {
                        escapedBack++;
                        return null;
                      },
                    ),
                  },
                  child: child!,
                ),
              ),
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.orange,
                  primary: Colors.orange,
                ),
              ),
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const BackupSetupWizard(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        checkStyles(tester);
        final l = AppLocalizations.of(
          tester.element(find.byType(BackupSetupWizard)),
        )!;
        final connection = find
            .text(
              destination == BackupDestination.local
                  ? l.backupLocal
                  : l.backupConnection,
            )
            .last;
        await tester.ensureVisible(connection);
        await tester.tap(connection);
        await tester.pumpAndSettle();
        expect(find.byType(BackupSetupWizard), findsNothing);
        expect(find.byType(Scaffold), findsOneWidget);
        checkStyles(tester);
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(escapedBack, 0);
        expect(find.byType(BackupSetupWizard), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(BackupSetupWizard), findsNothing);
      });
    }
  }
  for (final locale in ['ru', 'ar']) {
    testWidgets(
      'backup wizard stays inactive until final action on narrow screen $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _Setup()..mode = BackupMode.backup;
        final local = _Local();
        addTearDown(service.dispose);
        addTearDown(local.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BackupAutomationService>.value(
                value: service,
              ),
              ChangeNotifierProvider<AutomaticBackupService>.value(
                value: local,
              ),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const BackupSetupWizard(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(BackupSetupWizard)),
        )!;
        await tester.tap(find.text(l.backupLocal).last);
        await tester.pumpAndSettle();
        expect(find.byType(LocalBackupPage), findsOneWidget);
        final textContext = tester.element(find.text(l.backupFolderPath));
        expect(
          DefaultTextStyle.of(textContext).style.decoration,
          isNot(TextDecoration.underline),
        );
        expect(DefaultTextStyle.of(textContext).style.fontSize, lessThan(30));
        expect(
          find.ancestor(
            of: find.byType(LocalBackupPage),
            matching: find.byType(Scaffold),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        for (var step = 0; step < 3; step++) {
          checkStyles(tester);
          await tester.tap(find.byKey(const ValueKey('backupSetupNext')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(service.runs, 0);
          expect(service.enabled, isFalse);
        }
        await tester.tap(find.byKey(const ValueKey('backupSetupNext')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(service.runs, 1);
        expect(service.completed, isTrue);
        expect(service.enabled, isTrue);
      },
    );
  }
  testWidgets(
    'wizard alone collapses groups; explicit final choice starts exchange',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _Setup(), local = _Local();
      addTearDown(service.dispose);
      addTearDown(local.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BackupAutomationService>.value(
              value: service,
            ),
            ChangeNotifierProvider<AutomaticBackupService>.value(value: local),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BackupSetupWizard(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        checkStyles(tester);
        if (find.text(label).evaluate().isEmpty) {
          await tester.scrollUntilVisible(find.text(label), -300);
        }
        await tester.ensureVisible(find.text(label).last);
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tap('Next');
      expect(find.text('Synchronize everything'), findsOneWidget);
      expect(
        find.byKey(const ValueKey(BackupSyncGroup.topPanel)),
        findsNothing,
      );
      await tap('Synchronize everything');
      await tester.ensureVisible(
        find.byKey(const ValueKey(BackupSyncGroup.topPanel)),
      );
      await tester.tap(find.byKey(const ValueKey(BackupSyncGroup.topPanel)));
      await tester.pumpAndSettle();
      expect(service.disabled, contains(BackupSyncGroup.topPanel));
      final homeSwitch = find.byKey(const ValueKey('syncSection-home'));
      await tester.ensureVisible(homeSwitch);
      await tester.tap(homeSwitch);
      await tester.pumpAndSettle();
      expect(
        service.disabled,
        containsAll(backupSyncSections[BackupSyncSection.home]!),
      );
      expect(service.syncGroupEnabled(BackupSyncGroup.background), isTrue);
      await tester.tap(homeSwitch);
      await tester.pumpAndSettle();
      expect(
        backupSyncSections[BackupSyncSection.home]!.every(
          service.syncGroupEnabled,
        ),
        isTrue,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey(BackupSyncGroup.topPanel)),
      );
      await tester.tap(find.byKey(const ValueKey(BackupSyncGroup.topPanel)));
      await tester.pumpAndSettle();
      await tap('Synchronize everything');
      expect(service.disabled, isEmpty);
      expect(
        find.byKey(const ValueKey(BackupSyncGroup.topPanel)),
        findsNothing,
      );
      await tap('Synchronize everything');
      expect(service.disabled, contains(BackupSyncGroup.topPanel));
      await tap('Synchronize everything');
      await tap('Next');
      await tap('Next');
      expect(service.runs, 0);
      expect(
        tester
            .widget<LauncherDialogButton>(
              find.byKey(const ValueKey('backupSetupNext')),
            )
            .onPressed,
        isNull,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(BackupSetupWizard)),
      )!;
      await tap(l.backupSyncUseRemote);
      await tap('Next');
      expect(service.runs, 0);
      expect(
        find.text('Summary'),
        findsNothing,
      ); // Summary is part of the step subtitle.
      expect(find.byType(SettingsCheckboxTile), findsNothing);
      await tap(l.backupSetupStart);
      expect(service.runs, 1);
      expect(service.enabled, isTrue);
      // Ordinary settings remain an expanded group editor, without the master checkbox.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BackupAutomationService>.value(
              value: service,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: BackupSyncGroupsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synchronize everything'), findsNothing);
      expect(
        find.byKey(const ValueKey(BackupSyncGroup.topPanel)),
        findsOneWidget,
      );
    },
  );
}
