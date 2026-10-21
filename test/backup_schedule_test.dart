import 'package:flauncher/backup_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hourly slot catches up once and advances across midnight', () {
    const schedule = BackupSchedule(
      frequency: BackupFrequency.hourly,
      minute: 15,
    );
    expect(
      schedule.latestSlot(DateTime(2026, 10, 9, 0, 5)),
      DateTime(2026, 10, 8, 23, 15),
    );
    expect(
      schedule.nextSlot(DateTime(2026, 10, 9, 0, 5)),
      DateTime(2026, 10, 9, 0, 15),
    );
  });
  test('daily slot is calendar based, not 24 hours after last run', () {
    const schedule = BackupSchedule(hour: 3);
    expect(
      schedule.latestSlot(DateTime(2026, 10, 9, 2)),
      DateTime(2026, 10, 8, 3),
    );
    expect(
      schedule.nextSlot(DateTime(2026, 10, 9, 12)),
      DateTime(2026, 10, 10, 3),
    );
  });
  test('weekly slot uses chosen day and time across month boundaries', () {
    const schedule = BackupSchedule(
      frequency: BackupFrequency.weekly,
      weekday: DateTime.monday,
      hour: 18,
    );
    expect(
      schedule.latestSlot(DateTime(2026, 11, 2, 17)),
      DateTime(2026, 10, 26, 18),
    );
    expect(
      schedule.nextSlot(DateTime(2026, 11, 2, 17)),
      DateTime(2026, 11, 2, 18),
    );
  });
}
