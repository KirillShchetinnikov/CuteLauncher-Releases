import 'dart:async';
import 'dart:convert';

import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _DelayedStore extends InMemorySharedPreferencesStore {
  final saved = Completer<bool>();
  _DelayedStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await saved.future;
    return super.setValue(valueType, key, value);
  }
}

class _RejectOnceStore extends InMemorySharedPreferencesStore {
  bool reject = true;
  _RejectOnceStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject) {
      reject = false;
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'overlapping visibility and appearance changes preserve both choices',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = RemotePanelService(prefs);
      addTearDown(service.dispose);
      await Future.wait([
        service.show('network', false),
        service.show('time', false),
        service.setAppearance('panelOpacity', .5),
        service.setAppearance('panelTextSize', 20),
      ]);
      expect(service.visible('network'), isFalse);
      expect(service.visible('time'), isFalse);
      expect(service.ownAppearance.values['panelOpacity'], .5);
      expect(service.ownAppearance.values['panelTextSize'], 20);
      final restored = RemotePanelService(prefs);
      addTearDown(restored.dispose);
      expect(restored.visible('network'), isFalse);
      expect(restored.ownAppearance.values['panelOpacity'], .5);
    },
  );

  test(
    'closing the panel service during saving never notifies a disposed owner',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = _DelayedStore();
      SharedPreferencesStorePlatform.instance = store;
      final service = RemotePanelService(prefs);
      final task = service.show('network', false);
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      store.saved.complete(true);
      await expectLater(task, completes);
    },
  );

  test(
    'malformed hidden field from a compatible backup does not crash the panel',
    () async {
      final value = jsonEncode({
        'hidden': 'network',
        'inheritAppearance': false,
      });
      final imported = compatibleSettings({
        RemotePanelService.preferenceKey: value,
      }, {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        RemotePanelService.preferenceKey,
        imported[RemotePanelService.preferenceKey],
      );
      final service = RemotePanelService(prefs);
      addTearDown(service.dispose);
      expect(() => service.visible('network'), returnsNormally);
      expect(service.visible('network'), isTrue);
      expect(service.inheritAppearance, isFalse);
    },
  );

  test(
    'a rejected write preserves state and does not block the next change',
    () async {
      final prefs = await SharedPreferences.getInstance();
      SharedPreferencesStorePlatform.instance = _RejectOnceStore();
      final service = RemotePanelService(prefs);
      addTearDown(service.dispose);
      await expectLater(service.show('network', false), throwsStateError);
      expect(service.visible('network'), isTrue);
      await service.show('time', false);
      expect(service.visible('network'), isTrue);
      expect(service.visible('time'), isFalse);
    },
  );
  test('reopening the panel does not resurrect an edit rejected by storage', () async {
    final prefs = await SharedPreferences.getInstance();
    SharedPreferencesStorePlatform.instance = _RejectOnceStore();
    final service = RemotePanelService(prefs);
    addTearDown(service.dispose);
    await expectLater(service.show('network', false), throwsStateError);
    final reopened = RemotePanelService(prefs);
    addTearDown(reopened.dispose);
    expect(reopened.visible('network'), isTrue);
  });
}
