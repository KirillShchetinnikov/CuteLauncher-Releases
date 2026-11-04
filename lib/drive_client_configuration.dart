import 'dart:convert';

/// Client fields from a Google Cloud installed-app download.
/// URLs in the document never override Google's authorization endpoints.
class DriveClientConfiguration {
  static const maximumBytes = 64 * 1024;
  final String clientId;
  final String clientSecret;

  const DriveClientConfiguration(this.clientId, this.clientSecret);

  factory DriveClientConfiguration.parse(String source) {
    // Exceptions must not retain input containing secrets.
    const invalid = FormatException('Invalid Google Drive client document');
    if (utf8.encode(source).length > maximumBytes) throw invalid;
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw invalid;
    }
    if (decoded is! Map || decoded['installed'] is! Map) throw invalid;
    final installed = decoded['installed'] as Map;
    String field(String key) {
      final value = installed[key];
      if (value is! String) throw invalid;
      final trimmed = value.trim();
      if (trimmed.isEmpty ||
          trimmed.length > 256 ||
          RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(trimmed)) {
        throw invalid;
      }
      return trimmed;
    }

    return DriveClientConfiguration(field('client_id'), field('client_secret'));
  }
}
