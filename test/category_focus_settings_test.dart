import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final mode in CardFocusMode.values) {
    test('Home focus mode $mode persists and round-trips in backup', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      await settings.setCardFocusMode(mode);
      final restored = SettingsService(prefs);
      expect(restored.cardFocusMode, mode);
      final map = settings.exportSettingsMap();
      await settings.setCardFocusMode(CardFocusMode.remember);
      await settings.importSettingsMap(map);
      expect(settings.cardFocusMode, mode);
      await settings.importSettingsMap({'card_focus_mode': 'invalid'});
      expect(settings.cardFocusMode, mode);
      settings.dispose(); restored.dispose();
    });
  }
  test('old section memory does not change Home mode', () async {
    for (final remember in [true, false]) {
      SharedPreferences.setMockInitialValues({'remember_category_focus': remember});
      final settings = SettingsService(await SharedPreferences.getInstance());
      expect(settings.cardFocusMode, CardFocusMode.first);
      settings.dispose();
    }
  });

  test(
    'focus restoration preference persists and round-trips in backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      expect(settings.rememberCategoryFocus, isFalse);
      await settings.setRememberCategoryFocus(false);
      final restored = SettingsService(prefs);
      expect(restored.rememberCategoryFocus, isFalse);
      final map = settings.exportSettingsMap();
      await settings.setRememberCategoryFocus(true);
      await settings.importSettingsMap(map);
      expect(settings.rememberCategoryFocus, isFalse);
      await settings.importSettingsMap({'remember_category_focus': 'yes'});
      expect(settings.rememberCategoryFocus, isFalse);
      settings.dispose();
      restored.dispose();
    },
  );
}
