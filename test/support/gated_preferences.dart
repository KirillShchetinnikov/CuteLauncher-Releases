import 'dart:async';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class GatedPreferencesStore extends InMemorySharedPreferencesStore {
  GatedPreferencesStore([Map<String, Object> data = const {}])
    : super.withData(Map.of(data));

  Completer<void>? writeGate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await writeGate?.future;
    return super.setValue(valueType, key, value);
  }
}
