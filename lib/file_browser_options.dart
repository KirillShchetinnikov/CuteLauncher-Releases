import 'dart:convert';

const fileBrowserOptionsKey = 'file_browser_options';
const fileBrowserLocationsKey = 'file_browser_locations';

enum FileBrowserStart { storage, downloads, last }

enum FileBrowserSort { name, date, size }

class FileBrowserOptions {
  final FileBrowserStart start;
  final FileBrowserSort sort;
  final bool descending, foldersFirst, showHidden, showDetails;

  const FileBrowserOptions({
    this.start = FileBrowserStart.last,
    this.sort = FileBrowserSort.name,
    this.descending = false,
    this.foldersFirst = true,
    this.showHidden = false,
    this.showDetails = true,
  });

  @override
  bool operator ==(Object other) =>
      other is FileBrowserOptions &&
      start == other.start &&
      sort == other.sort &&
      descending == other.descending &&
      foldersFirst == other.foldersFirst &&
      showHidden == other.showHidden &&
      showDetails == other.showDetails;

  @override
  int get hashCode => Object.hash(
    start,
    sort,
    descending,
    foldersFirst,
    showHidden,
    showDetails,
  );

  FileBrowserOptions copyWith({
    FileBrowserStart? start,
    FileBrowserSort? sort,
    bool? descending,
    bool? foldersFirst,
    bool? showHidden,
    bool? showDetails,
  }) => FileBrowserOptions(
    start: start ?? this.start,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
    foldersFirst: foldersFirst ?? this.foldersFirst,
    showHidden: showHidden ?? this.showHidden,
    showDetails: showDetails ?? this.showDetails,
  );

  String encode() => jsonEncode({
    'start': start.name,
    'sort': sort.name,
    'descending': descending,
    'foldersFirst': foldersFirst,
    'showHidden': showHidden,
    'showDetails': showDetails,
  });

  static FileBrowserOptions? tryDecode(Object? raw) {
    if (raw is! String) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final start = FileBrowserStart.values
          .where((v) => v.name == (data['start'] ?? 'last'))
          .firstOrNull;
      final sort = FileBrowserSort.values
          .where((v) => v.name == (data['sort'] ?? 'name'))
          .firstOrNull;
      if (start == null || sort == null) return null;
      for (final key in [
        'descending',
        'foldersFirst',
        'showHidden',
        'showDetails',
      ]) {
        if (data.containsKey(key) && data[key] is! bool) return null;
      }
      return FileBrowserOptions(
        start: start,
        sort: sort,
        descending: data['descending'] ?? false,
        foldersFirst: data['foldersFirst'] ?? true,
        showHidden: data['showHidden'] ?? false,
        showDetails: data['showDetails'] ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sort the bounded native listing once, keeping unknown metadata at the end.
  List<Map> entries(Map<Object?, Object?>? data) {
    final result =
        <Map>[
              for (final entry in data?['folders'] as List? ?? const [])
                {...entry as Map, 'directory': true},
              for (final entry in data?['files'] as List? ?? const [])
                {...entry as Map, 'directory': false},
            ]
            .where(
              (entry) =>
                  showHidden || !(entry['name'] as String).startsWith('.'),
            )
            .toList();
    int byName(Map a, Map b) {
      final first = a['name'] as String, second = b['name'] as String;
      final lower = first.toLowerCase().compareTo(second.toLowerCase());
      final exact = lower == 0 ? first.compareTo(second) : lower;
      return exact == 0
          ? (a['path'] as String).compareTo(b['path'] as String)
          : exact;
    }

    num metadata(Map entry) {
      final value = sort == FileBrowserSort.size
          ? (entry['directory'] == true ? null : entry['size'])
          : entry['modified'];
      return value is num &&
              value.isFinite &&
              value >= (sort == FileBrowserSort.size ? 0 : 1)
          ? value
          : -1;
    }

    result.sort((a, b) {
      if (foldersFirst && a['directory'] != b['directory']) {
        return a['directory'] == true ? -1 : 1;
      }
      var order = 0;
      if (sort != FileBrowserSort.name) {
        final first = metadata(a), second = metadata(b);
        if ((first < 0) != (second < 0)) {
          return first < 0 ? 1 : -1;
        }
        order = first.compareTo(second);
      }
      if (order == 0) order = byName(a, b);
      return descending ? -order : order;
    });
    return result;
  }
}
