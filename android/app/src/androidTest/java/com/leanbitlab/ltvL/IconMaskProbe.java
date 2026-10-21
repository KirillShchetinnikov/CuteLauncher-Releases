package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.drawable.AdaptiveIconDrawable;
import android.os.Build;
import android.os.Bundle;
import java.io.File;
import java.io.FileOutputStream;

/** Renders installed APK layers with the runtime system mask and common mask shapes. */
public final class IconMaskProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Emulator required");
            var context = getTargetContext();
            var drawable = context.getApplicationInfo().loadIcon(context.getPackageManager());
            if (!(drawable instanceof AdaptiveIconDrawable)) throw new AssertionError("Adaptive icon missing");
            AdaptiveIconDrawable icon = (AdaptiveIconDrawable) drawable;
            Bitmap bitmap = Bitmap.createBitmap(1000, 330, Bitmap.Config.ARGB_8888);
            try {
                Canvas canvas = new Canvas(bitmap); canvas.drawColor(Color.rgb(28, 32, 41));
                Paint label = new Paint(Paint.ANTI_ALIAS_FLAG); label.setColor(Color.WHITE); label.setTextSize(22);
                String[] names = {"Android system", "Circle", "Squircle", "Rounded square"};
                int size = 180;
                for (int i = 0; i < 4; i++) {
                    int saved = canvas.save();
                    canvas.translate(35 + i * 250, 45);
                    icon.setBounds(0, 0, size, size);
                    if (i == 0) icon.draw(canvas);
                    else {
                        Path mask = new Path();
                        if (i == 1) mask.addCircle(90, 90, 90, Path.Direction.CW);
                        if (i == 2) {
                            mask.moveTo(90, 0);
                            mask.cubicTo(180, 0, 180, 0, 180, 90);
                            mask.cubicTo(180, 180, 180, 180, 90, 180);
                            mask.cubicTo(0, 180, 0, 180, 0, 90);
                            mask.cubicTo(0, 0, 0, 0, 90, 0); mask.close();
                        }
                        if (i == 3) mask.addRoundRect(0, 0, 180, 180, 36, 36, Path.Direction.CW);
                        canvas.clipPath(mask);
                        icon.getBackground().draw(canvas); icon.getForeground().draw(canvas);
                    }
                    canvas.restoreToCount(saved);
                    canvas.drawText(names[i], 35 + i * 250, 275, label);
                }
                File output = new File(context.getExternalFilesDir(null), "icon-masks.png");
                try (FileOutputStream stream = new FileOutputStream(output)) { bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream); }
                report.putString("stream", "\nPASS: installed adaptive icon rendered. " + output.getAbsolutePath() + "\n");
                finish(Activity.RESULT_OK, report);
            } finally { bitmap.recycle(); }
        } catch (Exception | AssertionError error) {
            report.putString("stream", "\nFAIL: " + error.getClass().getSimpleName() + ": " + error.getMessage() + "\n");
            finish(Activity.RESULT_CANCELED, report);
        }
    }
}
