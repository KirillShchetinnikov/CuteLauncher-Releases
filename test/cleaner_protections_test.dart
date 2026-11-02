import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('negative rules are included in application assets', () async {
    expect(jsonDecode(await rootBundle.loadString('catalog/cleaner_protections.json')),
        jsonDecode(File('catalog/cleaner_protections.json').readAsStringSync()));
  });
  test('bundled protection rules are exact negative rules with evidence', () {
    final catalog = jsonDecode(File('catalog/cleaner_protections.json').readAsStringSync()) as Map;
    expect(catalog['schemaVersion'], 1);
    final ids = <String>{};
    for (final rule in catalog['rules'] as List) {
      expect(ids.add(rule['id']), true);
      final identity = rule['identity'] as Map;
      expect(identity['manufacturer'], isNotEmpty);
      expect(identity['model'], isNotEmpty);
      expect(identity.containsKey('fingerprint') || identity.containsKey('firmware'), true);
      expect(rule['verification'], 'upstreamObservedBreakage');
      expect(rule['source'], startsWith('https://github.com/Gathin23/cleanyourtv/'));
      expect(rule['protectedPackages'], isNotEmpty);
      expect(rule.containsKey('recommended'), false);
    }
  });
}
