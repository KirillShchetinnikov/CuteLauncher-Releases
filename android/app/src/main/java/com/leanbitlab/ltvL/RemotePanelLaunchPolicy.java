package com.leanbitlab.ltvL;

import androidx.annotation.NonNull;
import java.lang.ref.WeakReference;
import java.util.Objects;
import java.util.function.BooleanSupplier;
import java.util.function.Consumer;

/** Tracks launcher visibility on the main thread and blocks opening the remote panel on Home. */
final class RemotePanelLaunchPolicy {
    private final Consumer<Boolean> visibilityChanged;
    private WeakReference<Object> visibleHost = new WeakReference<>(null);

    RemotePanelLaunchPolicy(@NonNull Consumer<Boolean> visibilityChanged) {
        this.visibilityChanged = visibilityChanged;
    }

    void started(@NonNull Object host) {
        boolean wasVisible = launcherVisible();
        visibleHost = new WeakReference<>(Objects.requireNonNull(host));
        if (!wasVisible) visibilityChanged.accept(true);
    }

    void stopped(@NonNull Object host) {
        if (visibleHost.get() != host) return;
        visibleHost.clear();
        visibilityChanged.accept(false);
    }

    boolean launcherVisible() {
        return visibleHost.get() != null;
    }

    boolean toggle(boolean panelOpen, @NonNull BooleanSupplier toggle, @NonNull Runnable blockedNotice) {
        if (!panelOpen && launcherVisible()) {
            blockedNotice.run();
            return false;
        }
        return toggle.getAsBoolean();
    }
}
