package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.view.KeyEvent;

public class LauncherAccessibilityService extends AccessibilityService {
    private RemoteButtonRemapper remapper;
    private RemotePanelWindow panel;
    private RemotePanelWindow recents;
    static boolean showRecents() {
        var service = active.get();
        if (service == null) return false;
        if (service.panel != null) service.panel.close();
        if (service.recents == null) service.recents = new RemotePanelWindow(service, true);
        return service.recents.toggle();
    }
    boolean togglePanel() {
        if (recents != null) recents.close();
        return MainActivity.remotePanelPolicy.toggle(panel != null && panel.isOpen(), () -> {
            if (panel == null) panel = new RemotePanelWindow(this);
            return panel.toggle();
        }, MainActivity::panelBlocked);
    }
    static boolean showPanel() { var service = active.get(); return service != null && service.togglePanel(); }
    void dismissPanel() { if (panel != null) panel.requestClose(); if (recents != null) recents.requestClose(); }
    private static volatile java.lang.ref.WeakReference<LauncherAccessibilityService> active = new java.lang.ref.WeakReference<>(null);
    @Override protected void onServiceConnected() {
        super.onServiceConnected();
        active = new java.lang.ref.WeakReference<>(this);
        PermissionRecoveryScheduler.serviceConnected(this);
        if (remapper != null) remapper.close();
        remapper = new RemoteButtonRemapper(this);
        RemoteButtonsBridge.serviceChanged();
    }
    static boolean connected() { return active.get() != null; }
    @Override public void onDestroy() {
        if (recents != null) { recents.close(); recents = null; }
        if (panel != null) { panel.close(); panel = null; }
        if (remapper != null) { remapper.close(); remapper = null; }
        RemoteButtonLearning.reset();
        if (active.get() == this) active.clear();
        RemoteButtonsBridge.serviceChanged();
        super.onDestroy();
    }
    static boolean canSleep() {
        LauncherAccessibilityService service = active.get();
        try {
            return service != null && (android.os.Build.VERSION.SDK_INT < 30 || service.getSystemActions().stream()
                .anyMatch(action -> action.getId() == GLOBAL_ACTION_LOCK_SCREEN));
        } catch (RuntimeException e) { return false; }
    }
    static boolean sleep() {
        LauncherAccessibilityService service = active.get();
        try { return service != null && service.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN); }
        catch (RuntimeException e) { return false; }
    }
    @Override
    public void onAccessibilityEvent(android.view.accessibility.AccessibilityEvent event) {
        // Not used
    }

    @Override
    public void onInterrupt() {
        if (remapper != null) remapper.interrupt();
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        RemoteButtonsBridge.observe(event);
        if (recents != null && recents.event(event)) return true;
        if (panel != null && panel.event(event)) return true;
        if (remapper != null && remapper.event(event)) return true;
        if (RemoteButtonLearning.event(event)) return true;
        if (getSharedPreferences("launcher_control", MODE_PRIVATE).getBoolean("override_home", true)
                && event.getKeyCode() == KeyEvent.KEYCODE_HOME) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                Intent intent = new Intent(this, MainActivity.class);
                intent.putExtra("return_home", true);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                startActivity(intent);
            }
            return true; // Consume Home key event
        }
        return super.onKeyEvent(event);
    }
}
