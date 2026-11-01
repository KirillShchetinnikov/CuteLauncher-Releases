import 'dart:convert';

import 'initial_settings_profile.dart';

/// Omitted fields in an old backup must not inherit untouched first-run seeds.
/// User edits and explicitly supplied (even invalid) fields keep normal merge rules.
Map<String, dynamic> initialProfileRestoreBaseline(
  Map<String, dynamic> current,
  Map incoming,
) {
  final encoded = current[initialProfileSeedKey];
  if (encoded is! String) return {...current};
  Map seeds;
  try {
    seeds = jsonDecode(encoded) as Map;
  } catch (_) {
    return {...current};
  }
  bool same(dynamic a, dynamic b) => jsonEncode(a) == jsonEncode(b);
  Map<String, dynamic> strip(Map values, Map original, Map supplied) {
    final result = Map<String, dynamic>.from(values);
    for (final key in original.keys) {
      if (!values.containsKey(key)) continue;
      if (values[key] is Map &&
          original[key] is Map &&
          (!supplied.containsKey(key) || supplied[key] is Map)) {
        result[key] = strip(
          values[key] as Map,
          original[key] as Map,
          supplied[key] as Map? ?? {},
        );
        if (!supplied.containsKey(key) && (result[key] as Map).isEmpty) {
          result.remove(key);
        }
      } else if (!supplied.containsKey(key) &&
          same(values[key], original[key])) {
        result.remove(key);
      }
    }
    return result;
  }

  final baseline = {...current};
  for (final key in seeds.keys) {
    if (!current.containsKey(key)) continue;
    if (const {'tile_appearance', 'category_appearance'}.contains(key)) {
      try {
        final supplied = incoming.containsKey(key)
            ? jsonDecode(incoming[key] as String) as Map
            : <String, dynamic>{};
        baseline[key as String] = jsonEncode(
          strip(
            jsonDecode(current[key] as String) as Map,
            jsonDecode(seeds[key] as String) as Map,
            supplied,
          ),
        );
      } catch (_) {
        /* Invalid input retains current settings as before. */
      }
    } else if (!incoming.containsKey(key) && same(current[key], seeds[key])) {
      baseline.remove(key);
    }
  }
  return baseline;
}
