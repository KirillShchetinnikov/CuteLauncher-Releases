enum BackupFrequency { hourly, daily, weekly }

/// Calendar slots use local TV time; missed slots are caught up on resume.
class BackupSchedule {
  final BackupFrequency frequency;
  final int hour, minute, weekday;
  const BackupSchedule({
    this.frequency = BackupFrequency.daily,
    this.hour = 3,
    this.minute = 0,
    this.weekday = DateTime.monday,
  });

  DateTime latestSlot(DateTime now) {
    var slot = DateTime(
      now.year,
      now.month,
      now.day,
      frequency == BackupFrequency.hourly ? now.hour : hour,
      minute,
    );
    if (frequency == BackupFrequency.weekly) {
      slot = DateTime(
        slot.year,
        slot.month,
        slot.day - (slot.weekday - weekday + 7) % 7,
        hour,
        minute,
      );
    }
    if (slot.isAfter(now)) {
      if (frequency == BackupFrequency.hourly) {
        slot = DateTime(slot.year, slot.month, slot.day, slot.hour - 1, minute);
      } else {
        slot = DateTime(
          slot.year,
          slot.month,
          slot.day - (frequency == BackupFrequency.weekly ? 7 : 1),
          hour,
          minute,
        );
      }
    }
    return slot;
  }

  DateTime nextSlot(DateTime now) {
    final slot = latestSlot(now);
    return frequency == BackupFrequency.hourly
        ? DateTime(slot.year, slot.month, slot.day, slot.hour + 1, minute)
        : DateTime(
            slot.year,
            slot.month,
            slot.day + (frequency == BackupFrequency.weekly ? 7 : 1),
            hour,
            minute,
          );
  }
}
