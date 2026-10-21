package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

/** Read-only app_process probe of the same metadata detector, without installing an APK. */
public final class AdbCapabilitiesProbe {
    public static void main(String[] args) throws Exception {
        android.os.Looper.prepare();
        Class<?> threadClass = Class.forName("android.app.ActivityThread");
        Object thread = threadClass.getMethod("systemMain").invoke(null);
        Context context = (Context)threadClass.getMethod("getSystemContext").invoke(thread);
        Activity activity = new Activity() {
            @Override public PackageManager getPackageManager() { return context.getPackageManager(); }
            @Override public String getPackageName() { return "io.github.kirillshchetinnikov.cutelauncher"; }
        };
        var info = AdbCapabilities.info(activity);
        System.out.println(new org.json.JSONObject(info));
        for (var item : AdbCapabilities.homes(activity)) System.out.println(item.activityInfo.packageName+" "+item.activityInfo.name+" priority="+item.priority+" enabled="+item.activityInfo.enabled+" appEnabled="+item.activityInfo.applicationInfo.enabled);
        if (AdbCapabilities.canHome(activity)) throw new AssertionError("Pinned system HOME was not detected");
        if (!AdbCapabilities.watchNextPermission(activity).equals(AdbCapabilities.TV_LISTINGS)) throw new AssertionError("Wrong TV permission");
        String stock = info.get("system").equals("Google TV") ? "com.google.android.apps.tv.launcherx" : "com.google.android.tvlauncher";
        if (!AdbCapabilities.canDisable(activity, stock)) throw new AssertionError("Safe HOME replacement was blocked");
        System.out.println("Metadata detector passed: pinned HOME, safe replacement, Watch Next permission");
    }
}
