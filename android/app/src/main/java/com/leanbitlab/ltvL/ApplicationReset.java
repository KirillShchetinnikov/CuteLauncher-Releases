package com.leanbitlab.ltvL;

import android.app.ActivityManager;
import android.content.Context;
import androidx.annotation.NonNull;

/** Android owns the complete reset, including native stores and credentials. */
final class ApplicationReset {
    private ApplicationReset() { }

    static boolean request(@NonNull Context context) {
        ActivityManager manager = context.getSystemService(ActivityManager.class);
        // A successful request terminates this process. Do not delete individual
        // stores first: a rejected request must leave the installation intact.
        return manager != null && manager.clearApplicationUserData();
    }
}
