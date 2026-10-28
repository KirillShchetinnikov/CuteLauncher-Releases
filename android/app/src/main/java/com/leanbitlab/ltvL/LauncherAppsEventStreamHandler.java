package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.pm.LauncherApps;
import android.os.UserHandle;

import io.flutter.plugin.common.EventChannel;

public class LauncherAppsEventStreamHandler implements EventChannel.StreamHandler
{
    private final LauncherApps _launcherApps;

    private LauncherApps.Callback _launcherAppsCallback;

    LauncherAppsEventStreamHandler(Context context)
    {
        _launcherApps = (LauncherApps) context.getSystemService(Context.LAUNCHER_APPS_SERVICE);
    }

    @Override
    public void onCancel(Object arguments)
    {
        if (_launcherAppsCallback != null) _launcherApps.unregisterCallback(_launcherAppsCallback);
        _launcherAppsCallback = null;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events)
    {
        _launcherAppsCallback = new LauncherAppsCallback(events);
        _launcherApps.registerCallback(_launcherAppsCallback);
    }


    private class LauncherAppsCallback extends LauncherApps.Callback
    {
        private final EventChannel.EventSink _eventSink;

        public LauncherAppsCallback(EventChannel.EventSink eventSink)
        {
            _eventSink = eventSink;
        }

        @Override
        public void onPackageRemoved(String packageName, UserHandle user) {
            _eventSink.success(new java.util.HashMap<String, Object>() {{ put("action", "PACKAGE_REMOVED"); put("packageName", packageName); }});
        }

        // Disabled packages have no launch activity. Reconcile the catalog
        // while retaining saved layout and statistics in the database.
        private void catalogChanged(String... packages) {
            _eventSink.success(java.util.Map.of("action", "CATALOG_CHANGED",
                    "packages", java.util.Arrays.asList(packages)));
        }

        @Override
        public void onPackageAdded(String packageName, UserHandle user) {
            catalogChanged(packageName);
        }

        @Override
        public void onPackageChanged(String packageName, UserHandle user) {
            catalogChanged(packageName);
        }

        @Override
        public void onPackagesAvailable(String[] packageNames, UserHandle user, boolean replacing) {
            catalogChanged(packageNames);
        }

        @Override
        public void onPackagesUnavailable(String[] packageNames, UserHandle user, boolean replacing) {
            if (!replacing) catalogChanged(packageNames);
        }
    }
}
