package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.pm.LauncherApps;
import android.os.UserHandle;

import io.flutter.plugin.common.EventChannel;

public class LauncherAppsEventStreamHandler implements EventChannel.StreamHandler, AutoCloseable
{
    private final LauncherApps _launcherApps;

    private LauncherApps.Callback _launcherAppsCallback;
    private final ApplicationChanges changes;

    LauncherAppsEventStreamHandler(Context context, java.util.concurrent.Executor worker,
            java.util.concurrent.Executor callbacks)
    {
        _launcherApps = (LauncherApps) context.getSystemService(Context.LAUNCHER_APPS_SERVICE);
        final var pm = context.getPackageManager();
        changes = new ApplicationChanges(since -> {
            var result = pm.getChangedPackages(since);
            return result == null ? new ApplicationChanges.Snapshot(since, java.util.List.of())
                : new ApplicationChanges.Snapshot(result.getSequenceNumber(), result.getPackageNames());
        }, worker, callbacks);
    }

    void foreground(boolean value) { changes.foreground(value); }
    @Override public void close() { onCancel(null); }

    @Override
    public void onCancel(Object arguments)
    {
        changes.cancel();
        if (_launcherAppsCallback != null) _launcherApps.unregisterCallback(_launcherAppsCallback);
        _launcherAppsCallback = null;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events)
    {
        onCancel(null);
        _launcherAppsCallback = new LauncherAppsCallback(events);
        _launcherApps.registerCallback(_launcherAppsCallback);
        changes.listen(packages -> events.success(java.util.Map.of(
                "action", "CATALOG_CHANGED", "packages", packages)));
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
            if (_launcherAppsCallback == this) _eventSink.success(java.util.Map.of(
                    "action", "PACKAGE_REMOVED", "packageName", packageName));
        }

        // Disabled packages have no launch activity. Reconcile the catalog
        // while retaining saved layout and statistics in the database.
        private void catalogChanged(String... packages) {
            if (_launcherAppsCallback == this) _eventSink.success(java.util.Map.of("action", "CATALOG_CHANGED",
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
