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
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.service.notification.StatusBarNotification;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.EventChannel;
/** Native NotificationBridge operations; channel names and payloads remain owned by MainActivity. */
final class NotificationBridge implements EventChannel.StreamHandler {
    private final Context context;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private LauncherNotificationListenerService.NotificationListener listener;
    private int generation;

    NotificationBridge(Context context) { this.context = context; }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        int subscription = generation;
        listener = () -> mainHandler.post(() -> {
            if (subscription != generation) return;
            try { events.success(getActiveNotifications()); }
            catch (Exception error) { error.printStackTrace(); }
        });
        LauncherNotificationListenerService.registerListener(listener);
        listener.onNotificationChanged();
    }

    @Override public void onCancel(Object arguments) {
        generation++;
        if (listener != null) {
            LauncherNotificationListenerService.unregisterListener(listener);
            listener = null;
        }
        mainHandler.removeCallbacksAndMessages(null);
    }

    boolean checkNotificationListenerPermission() {
        if (LauncherNotificationListenerService.getInstance() != null) {
            return true;
        }

        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            ComponentName cn = new ComponentName(context, LauncherNotificationListenerService.class);
            if (nm.isNotificationListenerAccessGranted(cn)) {
                return true;
            }
        }

        ComponentName listener = new ComponentName(context, LauncherNotificationListenerService.class);
        String flat = Settings.Secure.getString(context.getContentResolver(), "enabled_notification_listeners");
        if (flat != null && !flat.isEmpty()) {
            for (String name : flat.split(":")) {
                if (listener.equals(ComponentName.unflattenFromString(name))) {
                    return true;
                }
            }
        }
        return false;
    }

    boolean requestNotificationListenerPermission() {
        try {
            Intent detailIntent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS);
            ComponentName cn = new ComponentName(context, LauncherNotificationListenerService.class);
            detailIntent.putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, cn.flattenToString());
            detailIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (detailIntent.resolveActivity(context.getPackageManager()) != null) {
                context.startActivity(detailIntent);
                return true;
            }

            Intent intent = new Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (intent.resolveActivity(context.getPackageManager()) != null) {
                context.startActivity(intent);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    boolean openAppNotificationSettings() {
        try {
            Intent intent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (intent.resolveActivity(context.getPackageManager()) != null) {
                context.startActivity(intent);
                return true;
            }
            intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(Uri.parse("package:" + context.getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    List<Map<String, Object>> getActiveNotifications() {
        List<Map<String, Object>> list = new ArrayList<>();
        LauncherNotificationListenerService service = LauncherNotificationListenerService.getInstance();
        if (service == null) {
            return list;
        }
        try {
            StatusBarNotification[] sbns = service.getActiveNotifications();
            if (sbns != null) {
                for (StatusBarNotification sbn : sbns) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("key", sbn.getKey());
                    map.put("packageName", sbn.getPackageName());
                    
                    android.app.Notification notification = sbn.getNotification();
                    String title = "";
                    String text = "";
                    if (notification != null && notification.extras != null) {
                        CharSequence titleChar = notification.extras.getCharSequence(android.app.Notification.EXTRA_TITLE);
                        CharSequence textChar = notification.extras.getCharSequence(android.app.Notification.EXTRA_TEXT);
                        if (titleChar != null) title = titleChar.toString();
                        if (textChar != null) text = textChar.toString();
                    }
                    map.put("title", title);
                    map.put("text", text);
                    map.put("isClearable", sbn.isClearable());
                    map.put("hasContentIntent", notification != null && notification.contentIntent != null);
                    list.add(map);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    boolean openNotification(String key) {
        LauncherNotificationListenerService service = LauncherNotificationListenerService.getInstance();
        if (service == null || key == null) return false;
        try {
            StatusBarNotification[] notifications = service.getActiveNotifications(new String[]{key});
            if (notifications == null) return false;
            for (StatusBarNotification item : notifications) {
                if (!key.equals(item.getKey())) continue;
                android.app.Notification notification = item.getNotification();
                if (notification == null || notification.contentIntent == null) return false;
                notification.contentIntent.send();
                return true;
            }
        } catch (Exception error) {
            error.printStackTrace();
        }
        return false;
    }

    boolean dismissNotification(String key) {
        LauncherNotificationListenerService service = LauncherNotificationListenerService.getInstance();
        if (service == null || key == null) {
            return false;
        }
        try {
            service.cancelNotification(key);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    boolean dismissAllNotifications() {
        LauncherNotificationListenerService service = LauncherNotificationListenerService.getInstance();
        if (service == null) {
            return false;
        }
        try {
            service.cancelAllNotifications();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

}
