package com.leanbitlab.ltvL.tests;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;
import com.leanbitlab.ltvL.TclBlueLight;

/** Verifies both transitions on real hardware and always restores the original state. */
public final class TclBlueLightProbe extends Instrumentation {
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        boolean passed = false;
        String message;
        try {
            TclBlueLight filter = new TclBlueLight();
            boolean original = filter.read();
            try {
                filter.set(!original);
                if (filter.read() == original) throw new AssertionError("Toggle did not change state");
                filter.set(original);
                if (filter.read() != original) throw new AssertionError("Restore failed");
                passed = true;
                message = "PASS: TCL filter changed " + original + " -> " + !original + " -> " + original;
            } finally {
                filter.set(original);
            }
        } catch (Throwable e) {
            passed = false;
            message = "FAIL: " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
        report.putString("stream", "\n" + message + "\n");
        finish(passed ? Activity.RESULT_OK : Activity.RESULT_CANCELED, report);
    }
}
