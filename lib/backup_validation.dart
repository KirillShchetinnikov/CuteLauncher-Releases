import 'models/category.dart';

/// Validate database integrity before either storage is changed.
/// Preferences are filtered separately by the compatible settings importer.
void validateBackup(Map<String, dynamic> data) {
  void require(bool valid) {
    if (!valid) throw const FormatException('Invalid backup data');
  }
  List<Map> rows(String key) {
    require(data[key] is List);
    final list = data[key] as List;
    require(list.every((row) => row is Map));
    return list.cast<Map>();
  }
  bool integer(Map row, String key, [int minimum = 0]) => row[key] is int && (row[key] as int) >= minimum;
  final apps = rows('apps');
  final categories = rows('categories');
  final memberships = rows('appsCategories');
  final spacers = rows('spacers');
  final packages = <String>{};
  final categoryIds = <int>{};
  final spacerIds = <int>{};
  final links = <String>{};
  final systemKeys = <String>{};
  for (final row in apps) {
    require(row['packageName'] is String && (row['packageName'] as String).isNotEmpty &&
      row['name'] is String && row['version'] is String && row['hidden'] is bool &&
      (row['lastLaunchedAt'] == null || row['lastLaunchedAt'] is int));
    if (row['lastLaunchedAt'] != null) DateTime.fromMillisecondsSinceEpoch(row['lastLaunchedAt'] as int);
    require(packages.add(row['packageName'] as String));
  }
  for (final row in categories) {
    require(integer(row, 'id', 1) && row['name'] is String && integer(row, 'order') &&
      integer(row, 'rowHeight', 1) && integer(row, 'columnsCount', 1) &&
      integer(row, 'sort') && (row['sort'] as int) < CategorySort.values.length &&
      integer(row, 'type') && (row['type'] as int) < CategoryType.values.length);
    require(categoryIds.add(row['id'] as int));
    require(row['visible'] == null || row['visible'] is bool);
    final systemKey = row['systemKey'];
    require(systemKey == null || (systemKey is String && Category.systemKeys.contains(systemKey) && systemKeys.add(systemKey)));
  }
  require(categories.isNotEmpty && categories.any((row) => row['visible'] != false));
  for (final row in spacers) {
    require(integer(row, 'id', 1) && integer(row, 'height') && integer(row, 'order'));
    require(spacerIds.add(row['id'] as int));
  }
  for (final row in memberships) {
    require(integer(row, 'categoryId', 1) && row['appPackageName'] is String && integer(row, 'order') &&
      categoryIds.contains(row['categoryId']) && packages.contains(row['appPackageName']));
    require(links.add('${row['categoryId']}:${row['appPackageName']}'));
  }
}
