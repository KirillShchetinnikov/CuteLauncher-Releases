import 'dart:async';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // SQLite 3 is provided by native asset hooks, as in the application build.
  await testMain();
}
