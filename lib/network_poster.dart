import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'image_limits.dart';

Future<Uint8List> readNetworkPoster(HttpClient client, Uri uri) async {
  HttpClientRequest? request;
  var abandoned = false;
  try {
    request = await client.getUrl(uri).then((value) {
      if (abandoned) value.abort();
      return value;
    }).timeout(const Duration(seconds: 5));
    final response = await request.close().timeout(const Duration(seconds: 5));
    if (response.statusCode != HttpStatus.ok) {
      throw FormatException('Poster HTTP ${response.statusCode}');
    }
    final bytes = await readBoundedImage(response).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Poster read', const Duration(seconds: 8)),
    );
    await validateImageBytes(bytes);
    return bytes;
  } catch (_) {
    abandoned = true;
    request?.abort();
    rethrow;
  }
}
