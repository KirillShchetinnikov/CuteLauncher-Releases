package com.leanbitlab.ltvL;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

final class LocalSolarTimes {
    private static final long DAY_MS = 86_400_000L;
    private static final long STEP_MS = 2 * 3_600_000L;
    private static final double HORIZON = Math.sin(Math.toRadians(-0.833));

    record Events(long sunrise, long sunset) {}
    private record Sample(long time, double height) {}

    private final double sinLatitude;
    private final double cosLatitude;
    private final double longitude;

    LocalSolarTimes(double latitude, double longitude) {
        sinLatitude = Math.sin(Math.toRadians(latitude));
        cosLatitude = Math.cos(Math.toRadians(latitude));
        this.longitude = longitude;
    }

    Events calculate(LocalDate date, ZoneId zone) {
        long start = date.atStartOfDay(zone).toInstant().toEpochMilli();
        long end = date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli();
        List<Sample> samples = new ArrayList<>();
        for (long time = start - STEP_MS; time <= end + 2 * STEP_MS; time += STEP_MS) {
            samples.add(new Sample(time, height(time)));
        }

        // Check around solar noon and midnight so short polar daylight or
        // darkness can cross the horizon between two samples on the same side.
        int sampleCount = samples.size();
        for (int i = 1; i + 1 < sampleCount; i++) {
            Sample left = samples.get(i - 1), middle = samples.get(i), right = samples.get(i + 1);
            if (middle.height > left.height && middle.height > right.height) {
                samples.add(extremum(left.time, right.time, true));
            } else if (middle.height < left.height && middle.height < right.height) {
                samples.add(extremum(left.time, right.time, false));
            }
        }
        samples.sort(Comparator.comparingLong(Sample::time));
        long sunrise = 0, sunset = 0;
        for (int i = 1; i < samples.size(); i++) {
            Sample left = samples.get(i - 1), right = samples.get(i);
            boolean rising = right.height >= 0;
            if ((left.height >= 0) == rising) continue;
            long crossing = crossing(left.time, right.time, rising);
            if (crossing < start || crossing >= end) continue;
            if (rising && sunrise == 0) sunrise = crossing;
            if (!rising) sunset = crossing;
        }
        return new Events(sunrise, sunset);
    }

    private Sample extremum(long left, long right, boolean maximum) {
        while (right - left > 1_000) {
            long step = (right - left) / 3;
            long first = left + step, second = right - step;
            if ((height(first) < height(second)) == maximum) left = first;
            else right = second;
        }
        long time = (left + right) / 2;
        return new Sample(time, height(time));
    }

    private long crossing(long left, long right, boolean rising) {
        while (right - left > 1_000) {
            long middle = (left + right) / 2;
            if ((height(middle) >= 0) == rising) right = middle;
            else left = middle;
        }
        return right;
    }

    // NOAA Solar Calculator equations for declination and equation of time.
    // The result is the sine of the altitude relative to the apparent horizon.
    private double height(long time) {
        double centuries = (time / (double) DAY_MS + 2_440_587.5 - 2_451_545) / 36_525;
        double meanLongitude = Math.toRadians((280.46646
            + centuries * (36_000.76983 + 0.0003032 * centuries)) % 360);
        double anomaly = Math.toRadians((357.52911
            + centuries * (35_999.05029 - 0.0001537 * centuries)) % 360);
        double eccentricity = 0.016708634 - centuries * (0.000042037 + 0.0000001267 * centuries);
        double center = Math.sin(anomaly) * (1.914602 - centuries * (0.004817 + 0.000014 * centuries))
            + Math.sin(2 * anomaly) * (0.019993 - 0.000101 * centuries)
            + Math.sin(3 * anomaly) * 0.000289;
        double omega = Math.toRadians(125.04 - 1934.136 * centuries);
        double apparentLongitude = meanLongitude
            + Math.toRadians(center - 0.00569 - 0.00478 * Math.sin(omega));
        double obliquity = Math.toRadians(23 + (26 + (21.448
            - centuries * (46.815 + centuries * (0.00059 - 0.001813 * centuries))) / 60) / 60
            + 0.00256 * Math.cos(omega));
        double declination = Math.asin(Math.sin(obliquity) * Math.sin(apparentLongitude));
        double y = Math.tan(obliquity / 2);
        y *= y;
        double equationOfTime = 4 * Math.toDegrees(
            y * Math.sin(2 * meanLongitude) - 2 * eccentricity * Math.sin(anomaly)
            + 4 * eccentricity * y * Math.sin(anomaly) * Math.cos(2 * meanLongitude)
            - 0.5 * y * y * Math.sin(4 * meanLongitude)
            - 1.25 * eccentricity * eccentricity * Math.sin(2 * anomaly));
        double solarMinutes = Math.floorMod(time, DAY_MS) / 60_000.0 + equationOfTime + 4 * longitude;
        double hourAngle = Math.toRadians(solarMinutes / 4 - 180);
        return sinLatitude * Math.sin(declination)
            + cosLatitude * Math.cos(declination) * Math.cos(hourAngle) - HORIZON;
    }
}
