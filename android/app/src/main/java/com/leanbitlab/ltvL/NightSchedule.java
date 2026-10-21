package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

public final class NightSchedule {
    public static List<long[]> intervals(JSONObject c, JSONArray days, long now) {
        List<long[]> result = new ArrayList<>();
        if (c.optBoolean("solar")) {
            for (int i = 0; i + 1 < days.length(); i++) {
                long sunset = days.optJSONObject(i).optLong("sunset"), sunrise = days.optJSONObject(i+1).optLong("sunrise");
                if (sunset <= 0 || sunrise <= 0) continue;
                long start = sunset + Math.max(-180, Math.min(180, c.optInt("sunsetOffset"))) * 60000L;
                long end = sunrise + Math.max(-180, Math.min(180, c.optInt("sunriseOffset"))) * 60000L;
                if (start < end) result.add(new long[]{start, end});
            }
        } else {
            int start = c.optInt("startHour") * 60 + c.optInt("startMinute");
            int end = c.optInt("endHour") * 60 + c.optInt("endMinute");
            if (start == end) return result;
            for (int offset = -1; offset <= 3; offset++) {
                Calendar day = Calendar.getInstance(); day.setTimeInMillis(now);
                day.add(Calendar.DAY_OF_MONTH, offset);
                day.set(Calendar.HOUR_OF_DAY, start / 60); day.set(Calendar.MINUTE, start % 60);
                day.set(Calendar.SECOND, 0); day.set(Calendar.MILLISECOND, 0);
                Calendar finish = (Calendar) day.clone();
                finish.set(Calendar.HOUR_OF_DAY, end / 60); finish.set(Calendar.MINUTE, end % 60);
                if (end <= start) finish.add(Calendar.DAY_OF_MONTH, 1);
                result.add(new long[]{day.getTimeInMillis(), finish.getTimeInMillis()});
            }
        }
        return result;
    }
    public static long next(JSONObject c, JSONArray days, long now, boolean start) {
        long next = Long.MAX_VALUE;
        for (long[] interval : intervals(c, days, now)) {
            long time = interval[start ? 0 : 1];
            if (time > now && time < next) next = time;
        }
        return next == Long.MAX_VALUE ? 0 : next;
    }
    public static boolean active(JSONObject c, JSONArray days, long now, boolean tcl) {
        return intensity(c, days, now) > 0;
    }
    public static double intensity(JSONObject c, JSONArray days, long now) {
        if (!c.optBoolean("enabled")) return 0;
        if (!c.optBoolean("scheduled")) return 1;
        String mode = c.optString("overrideMode", "none");
        if (!mode.equals("none") && now < c.optLong("overrideUntil")) return mode.equals("on") ? 1 : 0;
        long duration = c.optInt("transitionMinutes", 60) * 60000L;
        double intensity = 0;
        for (long[] interval : intervals(c, days, now)) {
            long ramp = interval[0] - duration;
            if (now >= ramp && now < interval[1])
                intensity = Math.max(intensity, Math.min(1, Math.min((now-ramp)/(double)duration,
                    (interval[1]-now)/(double)duration)));
        }
        return intensity;
    }
}
