package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import java.io.File;
import java.io.FileOutputStream;
import java.lang.reflect.Field;
import java.util.Map;

/** TV fallback/lifecycle check. Does not change battery exemption or HOME. */
public final class BatterySettingsGuideProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            var activity = startActivitySync(new Intent(getTargetContext(), MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            Thread.sleep(1500);
            if (NightOverlayService.batterySettingsAvailable(activity)) throw new AssertionError("Expected TV stub");
            String[] status = new String[1];
            runOnMainSync(() -> status[0] = NightOverlayService.openBatterySettings(activity, Map.of(
                "title", "CuteLauncher", "hint", "1. В разделе «Приложения» откройте «Специальный доступ».\n"
                    + "2. Выберите «Оптимизация энергопотребления» (иногда «Экономия энергии»).\n"
                    + "3. Найдите CuteLauncher; при необходимости выберите «Все приложения».\n"
                    + "4. Отключите оптимизацию или выберите «Без ограничений».\n"
                    + "Названия и доступность пунктов зависят от прошивки ТВ."), false));
            Thread.sleep(1500);
            if (!"opened".equals(status[0])) throw new AssertionError("Fallback failed: " + status[0]);
            Field instance = BatterySettingsGuide.class.getDeclaredField("instance");
            instance.setAccessible(true);
            if (((java.lang.ref.WeakReference<?>) instance.get(null)).get() == null) throw new AssertionError("Guide not visible");
            try (var descriptor = getUiAutomation().executeShellCommand("dumpsys window");
                 var input = new android.os.ParcelFileDescriptor.AutoCloseInputStream(descriptor)) {
                String windows = new String(input.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                if (!java.util.regex.Pattern.compile("(?m)^\\s*mCurrentFocus=Window\\{[^\\n]*com\\.android\\.tv\\.settings/")
                        .matcher(windows).find()) throw new AssertionError("System settings must keep input focus");
            }
            Bitmap screenshot = getUiAutomation().takeScreenshot();
            if (screenshot == null) throw new AssertionError("Screenshot unavailable");
            try (var output = new FileOutputStream(new File(getTargetContext().getCacheDir(), "battery-guide.png"))) {
                screenshot.compress(Bitmap.CompressFormat.PNG, 100, output);
            } finally { screenshot.recycle(); }
            runOnMainSync(() -> activity.startActivity(new Intent(activity, MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP)));
            Thread.sleep(1000);
            if (((java.lang.ref.WeakReference<?>) instance.get(null)).get() != null) throw new AssertionError("Guide leaked after resume");
            report.putString("result", "PASS: Apps fallback, overlay shown, removed after resume");
            finish(-1, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error);
            finish(0, report);
        }
    }
}
