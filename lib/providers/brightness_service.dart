import 'package:flauncher/bridge_result.dart';
/*
 * FLauncher
 * Copyright (C) 2024 LeanBitLab
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'service_lifecycle.dart';
import 'night_mode_service.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Time slot keys for storage
const _brightnessEnabled = "brightness_scheduler_enabled";
const _brightnessMorning = "brightness_morning"; // 6am - 9am
const _brightnessDay = "brightness_day"; // 9am - 3pm
const _brightnessAfternoon = "brightness_afternoon"; // 3pm - 6pm
const _brightnessEvening = "brightness_evening"; // 6pm - 10pm
const _brightnessNight = "brightness_night"; // 10pm - 6am

/// Time slot definitions
enum TimeSlot {
  morning, // 6am - 9am
  day, // 9am - 3pm
  afternoon, // 3pm - 6pm
  evening, // 6pm - 10pm
  night, // 10pm - 6am
}

extension TimeSlotExtension on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:
        return '6 AM - 9 AM';
      case TimeSlot.day:
        return '9 AM - 3 PM';
      case TimeSlot.afternoon:
        return '3 PM - 6 PM';
      case TimeSlot.evening:
        return '6 PM - 10 PM';
      case TimeSlot.night:
        return '10 PM - 6 AM';
    }
  }

  int get defaultBrightness {
    switch (this) {
      case TimeSlot.morning:
        return 60;
      case TimeSlot.day:
        return 100;
      case TimeSlot.afternoon:
        return 80;
      case TimeSlot.evening:
        return 50;
      case TimeSlot.night:
        return 20;
    }
  }
}

class BrightnessService extends ChangeNotifier with ServiceLifecycle {
  static const _platform = BridgeChannel('me.efesser.flauncher/method');
  final SharedPreferences _sharedPreferences;
  final NightModeService? nightMode;
  final DateTime Function() _now;
  int? _lastApplied;
  int? _lastWindowApplied;
  Timer? _timer;
  bool _checkingSchedule = false;
  Future<void> _brightnessOperation = Future.value();

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  BrightnessService(
    this._sharedPreferences, {
    this.nightMode,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    nightMode?.addListener(_nightChanged);
    checkPermission();
    // Start the scheduler if enabled
    if (isEnabled) {
      _startScheduler();
      applyCurrentSlotBrightness();
    }
  }

  Future<void> checkPermission() async {
    try {
      final permission =
          await _platform.invokeMethod<bool>('checkWriteSettingsPermission') ??
          false;
      if (isDisposed) return;
      _hasPermission = permission;
    } catch (e) {
      debugPrint('Error checking brightness permission: $e');
      if (isDisposed) return;
      _hasPermission = false;
    }
    if (isDisposed) return;
    notifyListeners();
  }

  Future<void> requestPermission() async {
    try {
      await _platform.invokeMethod('requestWriteSettingsPermission');
    } catch (e) {
      debugPrint('Error requesting brightness permission: $e');
    }
  }

  bool get isEnabled => _sharedPreferences.getBool(_brightnessEnabled) ?? false;
  bool get solarEnabled =>
      _sharedPreferences.getBool('brightness_solar') ?? false;
  bool get linkedUsesSolar => nightMode?.configuration.solar ?? true;
  int get transitionMinutes =>
      (_sharedPreferences.getInt('brightness_transition_minutes') ?? 1).clamp(
        1,
        60,
      );
  int get sunriseBrightness =>
      (_sharedPreferences.getInt('brightness_sunrise') ?? 80).clamp(0, 100);
  int get sunsetBrightness =>
      (_sharedPreferences.getInt('brightness_sunset') ?? 20).clamp(0, 100);
  bool get solarAvailable => _linkedBrightnessAt(_now()) != null;

  int? _linkedBrightnessAt(DateTime now) {
    final config = nightMode?.configuration;
    if (config == null) return null;
    final intervals = config.intervals(now, solarDays: nightMode!.solarDays);
    return brightnessAtBoundaries(
      now,
      [
        for (final interval in intervals) ...[
          (interval.$1, false),
          (interval.$2, true),
        ],
      ],
      day: sunriseBrightness,
      night: sunsetBrightness,
      minutes: transitionMinutes,
    );
  }

  Future<void> setSolarEnabled(bool enabled) async {
    await _sharedPreferences.setBool('brightness_solar', enabled);
    _lastApplied = null;
    if (enabled) await nightMode?.refreshSolar();
    await applyCurrentSlotBrightness();
    notifyListeners();
  }

  Future<void> setTransitionMinutes(int minutes) async {
    if (minutes < 1 || minutes > 60) throw ArgumentError.value(minutes);
    await _sharedPreferences.setInt('brightness_transition_minutes', minutes);
    await applyCurrentSlotBrightness();
    notifyListeners();
  }

  Future<void> setSolarBrightness(bool sunrise, int value) async {
    if (value < 0 || value > 100) throw ArgumentError.value(value);
    await _sharedPreferences.setInt(
      sunrise ? 'brightness_sunrise' : 'brightness_sunset',
      value,
    );
    await applyCurrentSlotBrightness();
    notifyListeners();
  }

  void _nightChanged() {
    if (solarEnabled && isEnabled) _checkSchedule();
    if (solarEnabled) notifyListeners();
  }

  /// Interpolate after a boundary; no guess is made without surrounding events.
  static int? solarBrightnessAt(
    DateTime now,
    List<Map<String, dynamic>> days, {
    required int day,
    required int night,
    required int minutes,
    int sunriseOffset = 0,
    int sunsetOffset = 0,
  }) {
    final events = <(DateTime, bool)>[];
    for (final value in days) {
      for (final sunrise in [true, false]) {
        final stamp = value[sunrise ? 'sunrise' : 'sunset'];
        if (stamp is int && stamp > 0) {
          events.add((
            DateTime.fromMillisecondsSinceEpoch(stamp)
                .add(Duration(minutes: sunrise ? sunriseOffset : sunsetOffset)),
            sunrise,
          ));
        }
      }
    }
    return brightnessAtBoundaries(
      now,
      events,
      day: day,
      night: night,
      minutes: minutes,
    );
  }

  static int? brightnessAtBoundaries(
    DateTime now,
    List<(DateTime, bool)> events, {
    required int day,
    required int night,
    required int minutes,
  }) {
    events.sort((a, b) => a.$1.compareTo(b.$1));
    final past = events.where((e) => !e.$1.isAfter(now)).toList();
    if (past.isEmpty || !events.any((e) => e.$1.isAfter(now))) return null;
    final boundary = past.last;
    final to = boundary.$2 ? day : night;
    final from = boundary.$2 ? night : day;
    final progress =
        (now.difference(boundary.$1).inMilliseconds /
                Duration(minutes: minutes).inMilliseconds)
            .clamp(0.0, 1.0);
    return (from + (to - from) * progress).round();
  }

  int getBrightnessForSlot(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return _sharedPreferences.getInt(_brightnessMorning) ??
            slot.defaultBrightness;
      case TimeSlot.day:
        return _sharedPreferences.getInt(_brightnessDay) ??
            slot.defaultBrightness;
      case TimeSlot.afternoon:
        return _sharedPreferences.getInt(_brightnessAfternoon) ??
            slot.defaultBrightness;
      case TimeSlot.evening:
        return _sharedPreferences.getInt(_brightnessEvening) ??
            slot.defaultBrightness;
      case TimeSlot.night:
        return _sharedPreferences.getInt(_brightnessNight) ??
            slot.defaultBrightness;
    }
  }

  Future<void> setBrightnessForSlot(TimeSlot slot, int brightness) async {
    String key;
    switch (slot) {
      case TimeSlot.morning:
        key = _brightnessMorning;
        break;
      case TimeSlot.day:
        key = _brightnessDay;
        break;
      case TimeSlot.afternoon:
        key = _brightnessAfternoon;
        break;
      case TimeSlot.evening:
        key = _brightnessEvening;
        break;
      case TimeSlot.night:
        key = _brightnessNight;
        break;
    }
    await _sharedPreferences.setInt(key, brightness);
    notifyListeners();

    // Apply immediately if this is the current slot and scheduler is enabled
    if (isEnabled && !solarEnabled && getCurrentTimeSlot() == slot) {
      await _serialize(() async {
        if (isEnabled) await _applyBrightness(brightness);
      });
    }
  }

  Future<void> setEnabled(bool enabled) =>
      _serialize(() => _setEnabled(enabled));

  Future<void> _serialize(Future<void> Function() action) {
    final next = _brightnessOperation.then((_) async {
      if (!isDisposed) await action();
    });
    _brightnessOperation = next.catchError((Object _) {});
    return next;
  }

  Future<void> _setEnabled(bool enabled) async {
    _lastApplied = null;
    await _sharedPreferences.setBool(_brightnessEnabled, enabled);
    if (isDisposed) return;

    if (enabled) {
      _startScheduler();
      // Apply brightness for current time slot immediately
      await _applyCurrentSlotBrightness();
    } else {
      _stopScheduler();
      // Restore the saved system baseline before resetting the window override.
      try {
        final restored =
            await _platform.invokeMethod<bool>('restoreSystemBrightness') ??
            false;
        if (!restored) {
          debugPrint(
            'System brightness restoration pending; baseline retained for retry',
          );
        }
      } catch (e) {
        debugPrint('Error restoring system brightness: $e');
      }
      // Reset to system brightness
      try {
        await ScreenBrightness().resetApplicationScreenBrightness();
        _lastWindowApplied = null;
      } catch (e) {
        debugPrint('Error resetting brightness: $e');
      }
    }

    notifyListeners();
  }

  TimeSlot getCurrentTimeSlot() {
    final now = _now();
    final hour = now.hour;

    if (hour >= 6 && hour < 9) {
      return TimeSlot.morning;
    } else if (hour >= 9 && hour < 15) {
      return TimeSlot.day;
    } else if (hour >= 15 && hour < 18) {
      return TimeSlot.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimeSlot.evening;
    } else {
      return TimeSlot.night;
    }
  }

  Future<void> applyCurrentSlotBrightness() =>
      _serialize(_applyCurrentSlotBrightness);

  Future<void> _applyCurrentSlotBrightness() async {
    if (isDisposed || !isEnabled) return;

    final now = _now();
    int? brightness;
    if (solarEnabled) {
      brightness = _linkedBrightnessAt(now);
    } else {
      final slot = getCurrentTimeSlot();
      const hours = [6, 9, 15, 18, 22];
      var boundary = DateTime(now.year, now.month, now.day, hours[slot.index]);
      if (boundary.isAfter(now)) {
        boundary = DateTime(
          now.year,
          now.month,
          now.day - 1,
          hours[slot.index],
        );
      }
      final previous =
          TimeSlot.values[(slot.index + TimeSlot.values.length - 1) %
              TimeSlot.values.length];
      final from = getBrightnessForSlot(previous),
          to = getBrightnessForSlot(slot);
      final progress =
          (now.difference(boundary).inMilliseconds /
                  Duration(minutes: transitionMinutes).inMilliseconds)
              .clamp(0.0, 1.0);
      brightness = (from + (to - from) * progress).round();
    }
    if (brightness == null ||
        (brightness == _lastApplied && _lastWindowApplied == null)) {
      return;
    }
    await _applyBrightness(brightness);
  }

  Future<void> _applyBrightness(int brightnessPct) async {
    bool success = false;
    try {
      // 1. Try system-wide brightness first (needs WRITE_SETTINGS)
      final int brightnessValue255 = ((brightnessPct / 100.0) * 255).round();
      success =
          await _platform.invokeMethod<bool>('setSystemBrightness', {
            'brightness': brightnessValue255,
          }) ??
          false;
    } catch (e) {
      debugPrint('Error setting system brightness ($brightnessPct%): $e');
    }
    if (success && _lastWindowApplied != null) {
      try {
        await ScreenBrightness().resetApplicationScreenBrightness();
        _lastWindowApplied = null;
      } catch (e) {
        debugPrint('Error clearing window brightness fallback: $e');
      }
    }
    if (!success &&
        !isDisposed &&
        isEnabled &&
        _lastWindowApplied != brightnessPct) {
      try {
        // Use window brightness even if the system channel failed or is absent.
        await ScreenBrightness().setApplicationScreenBrightness(
          brightnessPct / 100.0,
        );
        _lastWindowApplied = brightnessPct;
      } catch (e) {
        debugPrint('Error setting window brightness ($brightnessPct%): $e');
      }
    }
    if (success) _lastApplied = brightnessPct;
  }

  void _startScheduler() {
    if (isDisposed) return;
    _stopScheduler();
    // Short transitions need several steps per minute; unchanged values are skipped.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkSchedule();
    });
  }

  Future<void> _checkSchedule() async {
    if (_checkingSchedule || isDisposed) return;
    _checkingSchedule = true;
    try {
      await applyCurrentSlotBrightness();
    } catch (e) {
      debugPrint('Error checking brightness schedule: $e');
    } finally {
      _checkingSchedule = false;
    }
  }

  void _stopScheduler() {
    _timer?.cancel();
    _timer = null;
  }

  Future<double> getCurrentBrightness() async {
    try {
      return await ScreenBrightness().application;
    } catch (e) {
      return 1.0;
    }
  }

  @override
  void dispose() {
    nightMode?.removeListener(_nightChanged);
    _stopScheduler();
    super.dispose();
  }
}
