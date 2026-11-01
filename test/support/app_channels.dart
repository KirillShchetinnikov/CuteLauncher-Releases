import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/category.dart';

Category appChannelsGroup({
  int id = 987654,
  int order = 1,
  bool visible = true,
}) => Category(
  id: id,
  order: order,
  name: 'App Feeds',
  systemKey: 'app_channels',
  visible: visible,
  type: CategoryType.row,
);

class FeedChannel extends FLauncherChannel {
  final events = StreamController<dynamic>.broadcast(sync: true);
  List<Map<dynamic, dynamic>> data = [];
  final requests = <List<String>>[];
  final launches = <(String, String)>[];
  final posters = <String>[];
  Future<List<Map<dynamic, dynamic>>> Function()? response;
  Future<Uint8List?> Function()? posterResponse;
  bool fail = false;
  bool launchResult = true;
  @override
  Future<List<Map<dynamic, dynamic>>> getAppChannels(
    List<String> selected,
  ) async {
    requests.add(selected);
    if (fail) throw StateError('denied');
    return response == null ? data : response!();
  }

  @override
  StreamSubscription<dynamic> addAppChannelsChangedListener(
    void Function(dynamic) onEvent,
  ) => events.stream.listen(onEvent);
  @override
  Future<Uint8List?> getWatchNextPoster(String uri) async {
    posters.add(uri);
    return posterResponse == null ? null : posterResponse!();
  }

  @override
  Future<bool> launchAppChannelProgram(
    String intentUri,
    String packageName,
  ) async {
    launches.add((intentUri, packageName));
    return launchResult;
  }
}

Map<String, dynamic> feed(int id, {int count = 3, String poster = ''}) => {
  'id': id,
  'packageName': 'video.app',
  'name': 'Feed $id',
  'programs': [
    for (var i = 0; i < count; i++)
      {
        'id': id * 100 + i,
        'packageName': 'video.app',
        'title': 'Content $id/$i',
        'intentUri': 'video://watch/$id/$i',
        'posterArtUri': poster,
      },
  ],
};
