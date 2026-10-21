package com.leanbitlab.ltvL;

import java.util.Calendar;
import org.json.JSONArray;
import org.json.JSONObject;

/** Plain JVM regression tests; uses org.json, without an Android runtime. */
public final class NightScheduleTransitionTest {
    private static long time(int day, int hour, int minute) {
        Calendar value = Calendar.getInstance();
        value.clear(); value.set(2026, Calendar.OCTOBER, day, hour, minute);
        return value.getTimeInMillis();
    }
    private static void equals(double actual, double expected) {
        if (Math.abs(actual-expected) > .000001)
            throw new AssertionError("Expected " + expected + ", got " + actual);
    }
    public static void main(String[] args) throws Exception {
        JSONObject c = new JSONObject().put("enabled", true).put("scheduled", true)
            .put("startHour", 22).put("endHour", 7).put("transitionMinutes", 60);
        JSONArray days = new JSONArray();
        equals(NightSchedule.intensity(c, days, time(11,21,0)), 0);
        equals(NightSchedule.intensity(c, days, time(11,21,15)), .25);
        equals(NightSchedule.intensity(c, days, time(11,21,30)), .5);
        equals(NightSchedule.intensity(c, days, time(11,22,0)), 1);
        equals(NightSchedule.intensity(c, days, time(12,6,0)), 1);
        equals(NightSchedule.intensity(c, days, time(12,6,15)), .75);
        equals(NightSchedule.intensity(c, days, time(12,6,30)), .5);
        equals(NightSchedule.intensity(c, days, time(12,6,59)), 1.0/60);
        equals(NightSchedule.intensity(c, days, time(12,7,0)), 0);
        for (int day=10; day<=12; day++)
            days.put(new JSONObject().put("sunrise",time(day,7,0)).put("sunset",time(day,18,0)));
        c.put("solar",true).put("sunsetOffset",30);
        equals(NightSchedule.intensity(c,days,time(11,18,0)), .5);
        equals(NightSchedule.intensity(c,days,time(11,18,30)), 1);
        equals(NightSchedule.intensity(c,new JSONArray(),time(11,18,30)), 0);
        c.put("overrideMode","off").put("overrideUntil",time(11,19,0));
        equals(NightSchedule.intensity(c,days,time(11,18,30)), 0);
        if (NightSchedule.active(c,days,time(11,18,30),true))
            throw new AssertionError("TCL must follow the main override");
        c.put("overrideMode","none").put("sunsetOffset",360);
        equals(NightSchedule.intensity(c,days,time(11,20,30)), .5);
        c.put("sunriseOffset",30);
        equals(NightSchedule.intensity(c,days,time(12,7,0)), .5);
        for (String mode : new String[]{"on", "off"}) {
            c.put("overrideMode",mode).put("overrideUntil",time(12,7,30));
            equals(NightSchedule.intensity(c,days,time(12,7,0)), mode.equals("on") ? 1 : 0);
            equals(NightSchedule.intensity(c,days,time(12,7,30)), 0);
        }
        c.put("overrideMode","none");
        c.put("enabled",false);
        equals(NightSchedule.intensity(c,days,time(11,21,0)), 0);
        // Native overlay's flattened composition equals warm-then-black layers.
        for (double dim : new double[]{0, .3, .95})
            for (double warm : new double[]{0, .1, .9}) {
                double alpha = dim + warm*(1-dim);
                double factor = alpha == 0 ? 0 : warm*(1-dim)/alpha;
                for (double image : new double[]{0, .5, 1}) {
                    double layered = (image*(1-warm)+warm)*(1-dim);
                    double flattened = image*(1-alpha)+factor*alpha;
                    equals(flattened, layered);
                    if (flattened > 1-dim+.000001)
                        throw new AssertionError("Warmth exceeds the dimming ceiling");
                }
            }
        System.out.println("NightScheduleTransitionTest passed");
    }
}
