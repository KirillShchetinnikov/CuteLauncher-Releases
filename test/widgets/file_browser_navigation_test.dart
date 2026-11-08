import 'package:flauncher/file_browser_options.dart';
import 'package:flauncher/document_files.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/file_selection.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  const channel = MethodChannel('me.efesser.flauncher/method');
  late SettingsService settings;
  final requests = <Map>[];
  String? initialPath;
  String selectionKey = 'wallpaper:day';
  String operation = 'pickImageDocument';
  Object? result;
  var imagePicker = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    await settings.setFileManagerPreference(FileManagerPreference.builtIn);
    requests.clear();
    initialPath = null;
    selectionKey = 'wallpaper:day';
    operation = 'pickImageDocument';
    result = null;
    imagePicker = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestFileStorage') return true;
          if (call.method == 'browseLocalFiles') {
            final args = call.arguments as Map;
            requests.add(args);
            final path =
                args['path'] as String? ??
                (args['startFolder'] == 'downloads'
                    ? '/storage/main/Download'
                    : '/storage/main');
            return {
              'path': path,
              'uri': Uri.file(path, windows: false).toString(),
              'parent': '',
              'folders': [
                {'name': 'Photos', 'path': '$path/Photos'},
              ],
              'files': args['kind'] == 'folder'
                  ? []
                  : [
                      {'name': 'image.png', 'path': '$path/image.png'},
                    ],
            };
          }
          if (call.method == 'localDocumentOperation') {
            return '/private/staged.bin';
          }
          if (call.method == 'backupFolderOperation') return true;
          return null;
        });
  });
  tearDown(() {
    settings.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = imagePicker
                      ? await DocumentFiles.pickImage(
                          context: context,
                          selectionKey: selectionKey,
                        )
                      : await FileSelection.select<Object>(
                          context,
                          operation,
                          initialPath: initialPath,
                          selectionKey: selectionKey,
                        );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'image bookmark changes only after validation and successful application',
    (tester) async {
      await settings.rememberFileBrowserLocation(
        'selected:wallpaper:day',
        '/storage/old',
      );
      imagePicker = true;
      await pump(tester);
      await open(tester);
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('image.png'));
      await tester.pumpAndSettle();
      // Rejecting the staged image leaves the old applied image's folder intact.
      expect(
        settings.fileBrowserLocation('selected:wallpaper:day'),
        '/storage/old',
      );
      final image = result as XFile;
      await DocumentFiles.rememberImageSelection(image, settings);
      expect(
        settings.fileBrowserLocation('selected:wallpaper:day'),
        '/storage/old/Photos/',
      );
    },
  );

  testWidgets(
    'selected image folder overrides start mode and stays separate for day and night',
    (tester) async {
      await pump(tester);
      await open(tester);
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('image.png'));
      await tester.pumpAndSettle();
      expect(result, '/private/staged.bin');
      expect(
        settings.fileBrowserLocation('selected:wallpaper:day'),
        '/storage/main/Photos/',
      );
      await settings.setFileBrowserOptions(
        const FileBrowserOptions(start: FileBrowserStart.downloads),
      );
      await open(tester);
      expect(requests.last['path'], '/storage/main/Photos/');
      await close(tester);
      selectionKey = 'wallpaper:night';
      await open(tester);
      expect(requests.last['path'], isNull);
      expect(find.text('/storage/main/Download'), findsOneWidget);
      await close(tester);
      selectionKey = 'wallpaper:day';
      initialPath = '/storage/USB/SelectedFolder';
      await open(tester);
      expect(requests.last['path'], initialPath);
      await close(tester);
    },
  );

  testWidgets(
    'last visited folder survives cancellation but never replaces a selected image folder',
    (tester) async {
      await pump(tester);
      await open(tester);
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      await close(tester);
      await open(tester);
      expect(requests.last['path'], '/storage/main/Photos');
      expect(requests.last['initial'], isTrue);
      await tester.tap(find.text('image.png'));
      await tester.pumpAndSettle();
      await open(tester);
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      await close(tester);
      await open(tester);
      expect(requests.last['path'], '/storage/main/Photos/');
      await close(tester);
      operation = 'pickBackupFolder';
      initialPath = 'file:///storage/USB/Backups/';
      await open(tester);
      expect(requests.last['path'], initialPath);
      expect(find.byType(LocalFileBrowser), findsOneWidget);
      await close(tester);
    },
  );
}
