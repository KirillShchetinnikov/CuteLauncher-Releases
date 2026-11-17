import 'dart:io';

import 'package:path/path.dart' as p;

/// Deliberately limited source scan: expressions we cannot resolve fail closed.
({Set<String> names, Set<String> unresolved}) nativeStoreInventory(
  Directory root,
) {
  final sources = <String, String>{};
  final constants = <String, String>{};
  final tokens = RegExp(r'"(?:\\.|[^"\\])*"|/\*[\s\S]*?\*/|//[^\r\n]*');
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.java')) continue;
    final source = file.readAsStringSync().replaceAllMapped(tokens, (m) {
      return m[0]!.startsWith('/') ? ' ' : m[0]!;
    });
    sources[p.relative(file.path, from: root.path)] = source;
    for (final match in RegExp(
      r'\bstatic\s+final\s+String\s+(\w+)\s*=\s*"([a-zA-Z0-9_]+)"\s*[,;]',
    ).allMatches(source)) {
      constants['${p.basenameWithoutExtension(file.path)}.${match[1]}'] =
          match[2]!;
    }
  }
  final names = <String>{};
  final unresolved = <String>{};
  for (final entry in sources.entries) {
    for (final match in RegExp(
      r'\bgetSharedPreferences\s*\(\s*([^,]+),',
    ).allMatches(entry.value)) {
      final expression = match[1]!.trim();
      final literal = RegExp(r'^"([a-zA-Z0-9_]+)"$').firstMatch(expression);
      final constant =
          constants[expression.contains('.')
              ? expression
              : '${p.basenameWithoutExtension(entry.key)}.$expression'];
      if (literal != null || constant != null) {
        names.add(literal?[1] ?? constant!);
      } else {
        unresolved.add('${entry.key.replaceAll('\\', '/')}: $expression');
      }
    }
  }
  return (names: names, unresolved: unresolved);
}
