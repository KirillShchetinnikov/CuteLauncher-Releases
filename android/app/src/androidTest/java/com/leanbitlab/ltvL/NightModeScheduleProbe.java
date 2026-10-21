package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.os.SystemClock;
import android.view.View;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.Calendar;

/** Real TV regression check; restores configuration, AppOps and TCL filter in finally. */
public final class NightModeScheduleProbe extends Instrumentation {
    private void shell(String cmd) throws Exception {
        readShell(cmd);
    }
    private String readShell(String cmd) throws Exception {
        try (ParcelFileDescriptor result=getUiAutomation().executeShellCommand(cmd);
             java.io.FileInputStream in=new java.io.FileInputStream(result.getFileDescriptor());
             java.io.ByteArrayOutputStream bytes=new java.io.ByteArrayOutputStream()) {
            byte[] buffer=new byte[4096]; int count;
            while((count=in.read(buffer))!=-1) bytes.write(buffer,0,count);
            return bytes.toString(java.nio.charset.StandardCharsets.UTF_8.name());
        }
    }
    private static String mode(String output,String pattern) {
        var match=java.util.regex.Pattern.compile(pattern,java.util.regex.Pattern.MULTILINE).matcher(output);
        return match.find()?match.group(1):"default";
    }
    private void waitFor(java.util.function.BooleanSupplier condition,String message) throws Exception {
        waitFor(condition,message,250);
    }
    private void waitFor(java.util.function.BooleanSupplier condition,String message,int attempts) throws Exception {
        for(int i=0;i<attempts;i++) { if(condition.getAsBoolean()) return; SystemClock.sleep(100); }
        throw new AssertionError(message);
    }
    private void start(Context context,JSONObject c) throws Exception {
        // The HOME activity can restart during instrumentation and sync Flutter prefs.
        context.getSharedPreferences("FlutterSharedPreferences",Context.MODE_PRIVATE).edit()
            .putString("flutter.night_mode_configuration",c.toString()).commit();
        context.getSharedPreferences("night_overlay",Context.MODE_PRIVATE).edit().putString("configuration",c.toString()).commit();
        context.startForegroundService(new Intent(context,NightOverlayService.class));
        SystemClock.sleep(500);
    }
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); start();
    }
    @Override public void onStart() {
        Context context=getTargetContext();
        var prefs=context.getSharedPreferences("night_overlay",Context.MODE_PRIVATE);
        String previous=prefs.getString("configuration",null);
        var flutterPrefs=context.getSharedPreferences("FlutterSharedPreferences",Context.MODE_PRIVATE);
        String previousFlutter=flutterPrefs.getString("flutter.night_mode_configuration",null);
        boolean originalPresent=prefs.contains("tcl_original");
        boolean originalTcl=prefs.getBoolean("tcl_original",false);
        var solarPrefs=context.getSharedPreferences("night_solar",Context.MODE_PRIVATE);
        String previousSolarCache=solarPrefs.getString("cache",null);
        String uidMode="default",packageMode="default"; boolean modesRead=false;
        boolean tclOriginal=false,readTcl=false;
        Bundle report=new Bundle(); boolean passed=false;
        try {
            String pkg=context.getPackageName();
            uidMode=mode(readShell("appops get --uid "+pkg+" SYSTEM_ALERT_WINDOW"),"^\\s*Uid mode: SYSTEM_ALERT_WINDOW: (\\w+)");
            packageMode=mode(readShell("appops get "+pkg+" SYSTEM_ALERT_WINDOW"),"^\\s*SYSTEM_ALERT_WINDOW: (\\w+)");
            modesRead=true;
            TclBlueLight filter=new TclBlueLight(); tclOriginal=filter.read(); readTcl=true;
            shell("appops set --uid "+pkg+" SYSTEM_ALERT_WINDOW ignore");
            shell("appops set "+pkg+" SYSTEM_ALERT_WINDOW ignore");
            if(OverlayPermission.granted(context)) throw new AssertionError("Ignored AppOp reported granted");
            shell("appops set --uid "+pkg+" SYSTEM_ALERT_WINDOW allow");
            shell("appops set "+pkg+" SYSTEM_ALERT_WINDOW allow");
            if(!OverlayPermission.granted(context)) throw new AssertionError("Allowed AppOp reported denied");
            JSONObject c=new JSONObject().put("enabled",true).put("scheduled",true)
                .put("startHour",22).put("endHour",7).put("dim",20).put("warmth",5)
                .put("temperature",2700).put("tclScheduled",true);
            long now=System.currentTimeMillis();
            c.put("overrideMode","on").put("overrideUntil",now+60000)
                .put("tclOverrideMode","on").put("tclOverrideUntil",now+60000);
            if(!NightOverlayService.valid(c)) throw new AssertionError("Configuration rejected");
            start(context,c);
            waitFor(()->{try{return filter.read();}catch(Exception e){return false;}},"TCL scheduled ON failed");
            waitFor(()->Boolean.TRUE.equals(NightOverlayService.status(context,c).get("visible")),"Native overlay missing");
            c.put("overrideMode","off").put("tclOverrideMode","off"); start(context,c);
            waitFor(()->{try{return !filter.read();}catch(Exception e){return false;}},"TCL scheduled OFF failed");
            waitFor(()->!Boolean.TRUE.equals(NightOverlayService.status(context,c).get("visible")),"Native overlay retained during skip");
            JSONArray days=new JSONArray();
            days.put(new JSONObject().put("sunset",now-7200000).put("sunrise",now-36000000));
            days.put(new JSONObject().put("sunset",now+79200000).put("sunrise",now+36000000));
            JSONObject sun=new JSONObject(c.toString()).put("solar",true).put("sunsetOffset",60).put("sunriseOffset",-30)
                .put("overrideMode","none").put("tclOverrideMode","none");
            if(!NightSchedule.active(sun,days,now,false)) throw new AssertionError("Solar overnight offsets failed");
            if(NightSchedule.active(sun,days,now+34200000,false)) throw new AssertionError("Solar end boundary failed");
            report.putString("stream","\nPASS: permission deny/allow, real overlay, TCL scheduled ON/OFF, temporary skip and solar offsets.\n");
            JSONObject location=new JSONObject().put("solar",true).put("latitude",55.7558).put("longitude",37.6173);
            long refreshRequested=System.currentTimeMillis();
            NightSolarTimes.refresh(context,location,true,()->{});
            waitFor(()->!NightSolarTimes.loading(),"Solar fetch timeout",600);
            if(NightSolarTimes.cache(context,location).optLong("updated")<refreshRequested)
                throw new AssertionError("Live sunrise/sunset refresh failed; existing cache does not count as a network result");
            if(NightSolarTimes.days(context,location).length()<2) throw new AssertionError("Live sunrise/sunset data missing");
            if(NightSolarTimes.cities("Москва","ru").isEmpty()) throw new AssertionError("Live city search failed");
            passed=true;
            report.putString("stream",report.getString("stream")+"\nPASS: fresh sunrise/sunset and live city search.\n");
        } catch(Throwable e) {
            report.putString("stream",report.getString("stream","")+"\nFAIL: "+e+"\n");
            try {
                JSONObject nativeState=new JSONObject(prefs.getString("configuration","{}"));
                JSONObject flutterState=new JSONObject(flutterPrefs.getString("flutter.night_mode_configuration","{}"));
                report.putString("stream",report.getString("stream")+"STATE: native enabled="+nativeState.optBoolean("enabled")
                    +", tclScheduled="+nativeState.optBoolean("tclScheduled")+", flutter enabled="+flutterState.optBoolean("enabled")
                    +", flutter tclScheduled="+flutterState.optBoolean("tclScheduled")+"\n");
            } catch(Exception ignored) { }
        } finally {
            try {
                waitFor(()->!NightSolarTimes.loading(),"Solar worker did not finish before cache restoration",600);
                context.stopService(new Intent(context,NightOverlayService.class)); SystemClock.sleep(500);
                if(readTcl) new TclBlueLight().set(tclOriginal);
                if(originalPresent) prefs.edit().putBoolean("tcl_original",originalTcl).commit();
                else prefs.edit().remove("tcl_original").commit();
                if(previous==null) prefs.edit().remove("configuration").commit(); else prefs.edit().putString("configuration",previous).commit();
                if(previousFlutter==null) flutterPrefs.edit().remove("flutter.night_mode_configuration").commit();
                else flutterPrefs.edit().putString("flutter.night_mode_configuration",previousFlutter).commit();
                if(previousSolarCache==null) solarPrefs.edit().remove("cache").commit();
                else solarPrefs.edit().putString("cache",previousSolarCache).commit();
                if(modesRead) {
                    shell("appops set --uid "+context.getPackageName()+" SYSTEM_ALERT_WINDOW "+uidMode);
                    shell("appops set "+context.getPackageName()+" SYSTEM_ALERT_WINDOW "+packageMode);
                }
                if(previous!=null && new JSONObject(previous).optBoolean("enabled")) context.startForegroundService(new Intent(context,NightOverlayService.class));
            } catch(Throwable e) { passed=false; report.putString("stream",report.getString("stream")+"RESTORE FAILED: "+e+"\n"); }
        }
        finish(passed?Activity.RESULT_OK:Activity.RESULT_CANCELED,report);
    }
}
