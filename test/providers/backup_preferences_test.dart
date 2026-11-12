import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/backup_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'migrates only the former active mode without enabling the other',
    () async {
      SharedPreferences.setMockInitialValues({
        'backup_transport_mode': 1,
        'backup_transport_enabled': true,
        'backup_transport_destination': 1,
        'backup_transport_device': 'local-id',
        'backup_transport_sync_minutes': 30,
        'accent': 'orange',
        'sync_member_previous': 'excluded',
      });
      final source = await SharedPreferences.getInstance();
      final backup = BackupPreferences(source, 'backup'),
          sync = BackupPreferences(source, 'synchronization');
      await backup.migrate();
      await sync.migrate();
      expect(backup.getBool('backup_transport_enabled'), false);
      expect(sync.getBool('backup_transport_enabled'), true);
      expect(sync.getBool('backup_transport_setup_complete'), true);
      expect(backup.getBool('backup_transport_setup_complete'), false);
      expect(sync.getString('sync_member_previous'), 'excluded');
      expect(backup.getString('sync_member_previous'), isNull);
      await backup.setInt('backup_transport_destination', 0);
      expect(sync.getInt('backup_transport_destination'), 1);
      await backup.setString('backup_transport_device', 'same-id');
      expect(sync.getString('backup_transport_device'), 'same-id');
      await sync.setString('sync_member_other', 'excluded');
      expect(backup.getString('sync_member_other'), null);
      expect(sync.getString('accent'), 'orange');
      await sync.migrate();
      expect(sync.getInt('backup_transport_sync_minutes'), 30);
    },
  );
}
