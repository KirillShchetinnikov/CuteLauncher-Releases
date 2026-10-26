import 'dart:convert';
import 'dart:typed_data';

/// Best-effort local redaction. Reports should still be shared privately.
class DiagnosticRedactor {
  static const textLimit = 2048;
  static final _sensitive = RegExp(
    r'ssid|bssid|password|passwd|psk|token|secret|credential|private.?key|public.?key|account|e-?mail|username|host.?name|device.?name|serial|latitude|longitude|coordinates|(?:^|[\s,:])(?:ip|ipv4|ipv6|mac|address|gateway|dns|dhcp|url|uri|path|location)(?:$|[\s:=])',
    caseSensitive: false,
  );
  static final _privateKey = RegExp(
    r'ssid|bssid|password|passwd|psk|token|secret|credential|key|account|mail|user|host|serial|latitude|longitude|coordinates|address|gateway|dns|dhcp|url|uri|path|location|name|title|text|body|content|notification|package|target|component',
    caseSensitive: false,
  );
  static const _publicPackages = {
    'com.google.android.tungsten.setupwraith',
    'com.google.android.apps.tv.launcherx',
    'com.google.android.tvlauncher',
    'com.android.tv.launcher',
    'com.android.settings',
    'android.uid.system',
  };
  static String text(String raw) {
    final input = raw.substring(0, raw.length.clamp(0, 16384));
    var result = input
        .split('\n')
        .map((line) {
          if (RegExp(
            r'\b(?:ssid|bssid)\s*[:=]',
            caseSensitive: false,
          ).hasMatch(line)) {
            line = line.replaceAllMapped(
              RegExp(r'(\b(?:ssid|bssid)\s*[:=]).*', caseSensitive: false),
              (m) => '${m[1]} [redacted]',
            );
          } else if (_sensitive.hasMatch(line)) {
            return '[redacted personal data]';
          }
          return line
              .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'), '[ip]')
              .replaceAll(
                RegExp(
                  r'(?<![a-zA-Z0-9])(?:[a-fA-F0-9]{0,4}:){2,}[a-fA-F0-9:.%a-zA-Z0-9]*',
                ),
                '[ip]',
              )
              .replaceAll(
                RegExp(r'\b(?:[a-fA-F0-9]{2}[:-]){5}[a-fA-F0-9]{2}\b'),
                '[mac]',
              )
              .replaceAll(RegExp(r'\b[a-zA-Z][a-zA-Z0-9+.-]*://\S+'), '[uri]')
              .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+'), '[email]')
              .replaceAll(
                RegExp(
                  r'''(?:[a-zA-Z]:\\|/(?:data|storage|sdcard|mnt|home|users|tmp|private)/)[^\s'"]+''',
                ),
                '[path]',
              )
              .replaceAll(RegExp(r'"[^"]*"'), '"[redacted]"')
              .replaceAllMapped(
                RegExp(
                  r'\b[a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)+\b',
                ),
                (m) {
                  final value = m[0]!;
                  return _publicPackages.contains(value) ||
                          value.startsWith('com.leanbitlab.ltvL') ||
                          value.startsWith('java.') ||
                          value.startsWith('android.media.') ||
                          value.startsWith('androidx.media3.') ||
                          value.startsWith('io.flutter.plugins.videoplayer.') ||
                          value.startsWith('OMX.') ||
                          value.startsWith('c2.') ||
                          value.startsWith('android.permission.')
                      ? value
                      : '[identifier]';
                },
              )
              .replaceAll(RegExp(r'[\x00-\x08\x0b-\x1f\x7f]'), '');
        })
        .join('\n');
    final truncated = result.length > textLimit || raw.length > input.length;
    if (result.length > textLimit) result = result.substring(0, textLimit);
    return truncated ? '$result\n[truncated]' : result;
  }

  static Object? value(Object? raw, {int depth = 0}) {
    if (raw == null || raw is bool || raw is int) return raw;
    if (raw is double) return raw.isFinite ? raw : '[non-finite]';
    if (raw is String) return text(raw);
    if (depth >= 4) return '[depth limit]';
    if (raw is TypedData) return '[binary omitted]';
    if (raw is List) {
      return raw.take(12).map((item) => value(item, depth: depth + 1)).toList();
    }
    if (raw is Map) {
      final safe = <String, Object?>{};
      for (final entry in raw.entries.take(24)) {
        if (entry.key is! String) continue;
        final key = entry.key as String;
        if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,47}$').hasMatch(key)) continue;
        safe[key] = _privateKey.hasMatch(key)
            ? '[redacted]'
            : value(entry.value, depth: depth + 1);
      }
      return safe;
    }
    return '[object omitted]';
  }

  static String excerpt(Object? raw) {
    final safe = value(raw);
    final encoded = safe is String ? safe : jsonEncode(safe);
    return encoded.length > 8192
        ? '${encoded.substring(0, 8192)}\n[truncated]'
        : encoded;
  }
}
