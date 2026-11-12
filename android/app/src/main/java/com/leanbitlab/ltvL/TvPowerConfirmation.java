package com.leanbitlab.ltvL;

import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Configuration;
import android.text.TextUtils;
import android.view.WindowManager;

/** Confirmation over the current app, owned by the connected accessibility service. */
final class TvPowerConfirmation implements AutoCloseable {
    private final Context service;
    private AlertDialog dialog;
    private final BroadcastReceiver screenOff = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) { close(); }
    };

    TvPowerConfirmation(Context service) { this.service = service; }

    boolean isOpen() { return dialog != null && dialog.isShowing(); }

    boolean show(boolean reboot, Runnable confirm) {
        if (isOpen()) return false;
        close();

        String language = service.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.app_language", "");
        Configuration locale = new Configuration();
        locale.setLocale(LauncherDateFormat.locale(language));
        Context strings = service.createConfigurationContext(locale);
        String action = strings.getString(reboot ? R.string.power_reboot : R.string.power_off);
        var windowDialog = new AlertDialog.Builder(service, android.R.style.Theme_DeviceDefault_Dialog_Alert)
            .setTitle(action)
            .setMessage(strings.getString(reboot ? R.string.power_reboot_confirm : R.string.power_off_confirm))
            .setNegativeButton(strings.getString(android.R.string.cancel), null)
            .setPositiveButton(action, (source, button) -> {
                if (dialog != source || !isOpen()) return;
                close();
                confirm.run();
            })
            .create();
        var window = windowDialog.getWindow();
        window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY);
        windowDialog.setCanceledOnTouchOutside(false);
        windowDialog.setOnDismissListener(this::onDismiss);

        service.registerReceiver(screenOff, new IntentFilter(Intent.ACTION_SCREEN_OFF));
        dialog = windowDialog;
        try {
            windowDialog.show();
            window.getDecorView().setLayoutDirection(TextUtils.getLayoutDirectionFromLocale(locale.getLocales().get(0)));
            var cancel = windowDialog.getButton(DialogInterface.BUTTON_NEGATIVE);
            cancel.setFocusableInTouchMode(true);
            cancel.requestFocus();
        } catch (RuntimeException failure) {
            close();
            throw failure;
        }
        return true;
    }

    private void onDismiss(DialogInterface dismissed) {
        if (dialog != dismissed) return;
        dialog = null;
        service.unregisterReceiver(screenOff);
    }

    @Override public void close() {
        var current = dialog;
        if (current == null) return;
        onDismiss(current);
        current.dismiss();
    }
}
