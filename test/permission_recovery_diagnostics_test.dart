import 'package:flauncher/permission_recovery_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports bounded recovery state without credentials or arbitrary native output', () {
    final safe = permissionRecoveryDiagnostics({
      'status': 'adb_unavailable', 'health': 'connected', 'attempts': 2,
      'retryAt': 123, 'deadline': 456, 'lastChecked': 100,
      'pending': ['accessibility', 'accessibility', 'shell command', 42],
      'privateKey': 'secret', 'port': 5555, 'otherServices': ['private component'],
    });
    expect(safe['status'], 'adb_unavailable');
    expect(safe['pending'], ['accessibility']);
    expect(safe['attempts'], 2);
    expect(safe.containsKey('privateKey'), isFalse);
    expect(safe.containsKey('port'), isFalse);
    expect(safe.containsKey('otherServices'), isFalse);
    expect(permissionRecoveryDiagnostics({'status': 'untrusted text', 'attempts': 500})['status'], 'unknown');
    expect(permissionRecoveryDiagnostics({'attempts': 500}).containsKey('attempts'), isFalse);
  });
}
