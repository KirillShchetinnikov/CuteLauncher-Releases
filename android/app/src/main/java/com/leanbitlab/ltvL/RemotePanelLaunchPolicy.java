package com.leanbitlab.ltvL;

import androidx.annotation.NonNull;
import java.lang.ref.WeakReference;
import java.util.Objects;
import java.util.function.BooleanSupplier;

/** Main-thread policy: a visible launcher blocks opening, but never closing, a panel. */
final class RemotePanelLaunchPolicy {
    private WeakReference<Object> visibleHost = new WeakReference<>(null);

    void started(@NonNull Object host) {
        visibleHost = new WeakReference<>(Objects.requireNonNull(host));
    }

    void stopped(@NonNull Object host) {
        if (visibleHost.get() == host) visibleHost.clear();
    }

    boolean toggle(boolean panelOpen, @NonNull BooleanSupplier toggle, @NonNull Runnable blockedNotice) {
        if (!panelOpen && visibleHost.get() != null) {
            blockedNotice.run();
            return false;
        }
        return toggle.getAsBoolean();
    }
}
