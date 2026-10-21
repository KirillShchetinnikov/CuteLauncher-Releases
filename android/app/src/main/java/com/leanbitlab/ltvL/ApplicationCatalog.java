/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
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

package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.*;
import android.provider.Settings;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
/** Native ApplicationCatalog operations; channel names and payloads remain owned by MainActivity. */
final class ApplicationCatalog {
    private final Context context;

    ApplicationCatalog(Context context) { this.context = context; }

    List<Map<String, Serializable>> getApplications() {
        // The complete query runs on the shared worker pool, never the platform thread.
        List<ResolveInfo> tvActivitiesInfo = queryIntentActivities(false);
        List<ResolveInfo> nonTvActivitiesInfo = queryIntentActivities(true);
        if (tvActivitiesInfo == null || nonTvActivitiesInfo == null) {
            throw new IllegalStateException("PackageManager returned no query result");
        }
        List<Map<String, Serializable>> applications = new ArrayList<>();
        java.util.Set<String> packages = new java.util.HashSet<>();
        boolean settingsPresent = false;
        for (ResolveInfo info : tvActivitiesInfo) {
            if (info == null || info.activityInfo == null) continue;
            String name = info.activityInfo.packageName;
            if (packages.add(name)) applications.add(buildAppMap(info.activityInfo, false, null));
            settingsPresent |= name.equals("com.android.tv.settings");
        }
        for (ResolveInfo info : nonTvActivitiesInfo) {
            if (info == null || info.activityInfo == null) continue;
            String name = info.activityInfo.packageName;
            if (packages.add(name)) applications.add(buildAppMap(info.activityInfo, true, null));
            settingsPresent |= name.equals("com.android.settings");
        }

        if (!settingsPresent) {
            PackageManager packageManager = context.getPackageManager();
            Intent settingsIntent = new Intent(Settings.ACTION_SETTINGS);
            ActivityInfo activityInfo = settingsIntent.resolveActivityInfo(packageManager, 0);

            if (activityInfo != null) {
                if (packages.add(activityInfo.packageName)) {
                    applications.add(buildAppMap(activityInfo, false, Settings.ACTION_SETTINGS));
                }
            }
        }

        // Launcher queries omit service packages such as Google Partner Setup.
        for (PackageInfo info : context.getPackageManager().getInstalledPackages(0)) {
            if (info.applicationInfo != null && packages.add(info.packageName)) {
                applications.add(buildInstalledAppMap(info));
            }
        }
        return applications;
    }

    Map<String, Serializable> getApplication(String packageName) {
        Map<String, Serializable> map = new java.util.HashMap<>();
        PackageManager packageManager = context.getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        boolean sideloaded = intent == null;
        if (sideloaded) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        if (intent != null) {
            ActivityInfo activityInfo = intent.resolveActivityInfo(context.getPackageManager(), 0);

            if (activityInfo != null) {
                map = buildAppMap(activityInfo, sideloaded, null);
            }
        }

        if (map.isEmpty()) {
            try {
                map = buildInstalledAppMap(packageManager.getPackageInfo(packageName, 0));
            } catch (PackageManager.NameNotFoundException ignored) {
            }
        }
        return map;
    }

    byte[] getApplicationBanner(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = context.getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadBanner(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    byte[] getApplicationIcon(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = context.getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadIcon(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private List<ResolveInfo> queryIntentActivities(boolean sideloaded) {
        String category;
        if (sideloaded) {
            category = Intent.CATEGORY_LAUNCHER;
        } else {
            category = Intent.CATEGORY_LEANBACK_LAUNCHER;
        }

        // NOTE: Would be nice to query the applications that match *either* of the
        // above categories
        // but from the addCategory function documentation, it says that it will "use
        // activities
        // that provide *all* the requested categories"
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .addCategory(category);

        return context.getPackageManager()
                .queryIntentActivities(intent, 0);
    }

    private Map<String, Serializable> buildAppMap(ActivityInfo activityInfo, boolean sideloaded, String action) {
        PackageManager packageManager = context.getPackageManager();

        String applicationName = activityInfo.loadLabel(packageManager).toString(),
                applicationVersionName = "";
        try {
            applicationVersionName = packageManager.getPackageInfo(activityInfo.packageName, 0).versionName;
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        Map<String, Serializable> appMap = new HashMap<>();
        appMap.put("name", applicationName);
        appMap.put("packageName", activityInfo.packageName);
        appMap.put("version", applicationVersionName);
        appMap.put("sideloaded", sideloaded);
        appMap.put("launchable", true);
        appMap.put("system", (activityInfo.applicationInfo.flags
                & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0);

        if (action != null) {
            appMap.put("action", action);
        }
        return appMap;
    }

    private Map<String, Serializable> buildInstalledAppMap(PackageInfo info) {
        ApplicationInfo applicationInfo = info.applicationInfo;
        Map<String, Serializable> app = new HashMap<>();
        app.put("packageName", info.packageName);
        app.put("name", applicationInfo.loadLabel(context.getPackageManager()).toString());
        app.put("version", info.versionName == null ? "" : info.versionName);
        app.put("system", (applicationInfo.flags
                & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0);
        app.put("launchable", false);
        app.put("sideloaded", true);
        return app;
    }

    private byte[] drawableToByteArray(Drawable drawable) {
        if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) return new byte[0];
        Bitmap bitmap = drawableToBitmap(drawable);
        try {
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) return new byte[0];
            return stream.toByteArray();
        } finally { bitmap.recycle(); }
    }

    Bitmap drawableToBitmap(Drawable drawable) {
        double scale = Math.min(1.0, 960.0 / Math.max(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight()));
        int width = Math.max(1, (int) Math.ceil(drawable.getIntrinsicWidth() * scale));
        int height = Math.max(1, (int) Math.ceil(drawable.getIntrinsicHeight() * scale));
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, width, height);
        drawable.draw(canvas);
        return bitmap;
    }

}
