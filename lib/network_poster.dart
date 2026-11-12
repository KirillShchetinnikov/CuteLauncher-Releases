import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'image_limits.dart';
import 'diagnostics/poster_loads.dart';

Future<Uint8List> readNetworkPoster(
  HttpClient client,
  Uri uri, {
  PosterLoad? trace,
}) async {
  HttpClientRequest? request;
  var abandoned = false;
  try {
    trace?.stage(PosterStage.connection);
    request = await client
        .getUrl(uri)
        .then((value) {
          if (abandoned) value.abort();
          return value;
        })
        .timeout(const Duration(seconds: 5));
    trace?.stage(PosterStage.headers);
    final response = await request.close().timeout(const Duration(seconds: 5));
    trace?.response(response);
    if (response.statusCode != HttpStatus.ok) {
      // Once headers arrive, request.abort() no longer closes the response.
      // Cancel its body so errors cannot exhaust maxConnectionsPerHost.
      await response.listen(null).cancel();
      throw FormatException('Poster HTTP ${response.statusCode}');
    }
    trace?.stage(PosterStage.body);
    final bytes = await readBoundedImage(
      trace == null
          ? response
          : response.map((chunk) {
              trace.receivedBytes += chunk.length;
              return chunk;
            }),
      timeout: const Duration(seconds: 8),
    );
    trace?.stage(PosterStage.validation);
    await validateImageBytes(bytes);
    return bytes;
  } catch (error) {
    trace?.error(error);
    abandoned = true;
    request?.abort();
    rethrow;
  }
}
