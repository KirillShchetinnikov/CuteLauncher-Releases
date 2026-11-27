const showRemoteBatteryPercentKey = 'show_remote_battery_percent';
const remoteBatteryLowColorEnabledKey = 'remote_battery_low_color_enabled';
const remoteBatteryLowThresholdKey = 'remote_battery_low_threshold';
const remoteBatteryDefaultLowThreshold = 10;
const remoteBatteryMaxLowThreshold = 30;

bool isRemoteBatteryLowThreshold(Object? value) =>
    value is int && value >= 1 && value <= remoteBatteryMaxLowThreshold;
