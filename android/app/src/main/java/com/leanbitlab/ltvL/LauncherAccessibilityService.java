package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.view.KeyEvent;

public class LauncherAccessibilityService extends AccessibilityService {
    private RemoteButtonRemapper remapper;
    private VolumeKeyFilterPause volumePause;
    private VolumeKeyRepeater volumeRepeater;
    private int volumeWindowId = -1;
    private boolean volumeWatchEnabled;
    private final java.util.Map<String, Boolean> systemPackages = new java.util.LinkedHashMap<>();
    static void volumeConfigured(RemoteMappingConfiguration config) {
        var service = active.get();
        if (service == null || service.volumePause == null) return;
        service.volumePause.configure(config);
        service.volumeRepeater.configure(config);
        service.volumeWatchEnabled = config.enabled && (config.volumeMode.equals("auto") || config.volumeMode.equals("timed"));
    }
    private Boolean volumeVisible() {
        if (volumeWindowId < 0 || (getServiceInfo().getCapabilities()
                & android.accessibilityservice.AccessibilityServiceInfo.CAPABILITY_CAN_RETRIEVE_WINDOW_CONTENT) == 0) return null;
        var windows = getWindows();
        if (windows.isEmpty()) return null;
        for (var window : windows) if (window.getId() == volumeWindowId) return true;
        return false;
    }
    private boolean systemPackage(String pkg) {
        if (pkg == null) return false;
        Boolean known = systemPackages.get(pkg);
        if (known != null) return known;
        boolean system = false;
        try {
            system = (getPackageManager().getApplicationInfo(pkg, 0).flags
                & (android.content.pm.ApplicationInfo.FLAG_SYSTEM | android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0;
        } catch (android.content.pm.PackageManager.NameNotFoundException ignored) { }
        if (systemPackages.size() >= 32) systemPackages.remove(systemPackages.keySet().iterator().next());
        systemPackages.put(pkg, system); return system;
    }
    private boolean volumePanel(android.view.accessibility.AccessibilityEvent event) {
        if (!volumeWatchEnabled || event == null || event.getEventType() != android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return false;
        String pkg = event.getPackageName() == null ? null : event.getPackageName().toString();
        String name = event.getClassName() == null ? null : event.getClassName().toString();
        if (!systemPackage(pkg)) return false;
        if (VolumeKeyFilterPause.panel(pkg, name, null, true)) return true;
        // Only inspect metadata of the event source, never walk another app's UI tree.
        android.view.accessibility.AccessibilityNodeInfo source = event.getSource();
        if (source == null) return false;
        try { return VolumeKeyFilterPause.panel(pkg, name, source.getViewIdResourceName(), true); }
        finally { source.recycle(); }
    }
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
        if (volumePause != null) volumePause.close();
        if (volumeRepeater != null) volumeRepeater.close();
        var info = getServiceInfo();
        info.eventTypes |= android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            | android.view.accessibility.AccessibilityEvent.TYPE_WINDOWS_CHANGED; // Keep framework window cache current.
        info.packageNames = null; // Vendor SystemUI packages differ; validate system ownership per event.
        info.flags |= android.accessibilityservice.AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            | android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
        setServiceInfo(info);
        var handler = new android.os.Handler(android.os.Looper.getMainLooper());
        volumePause = new VolumeKeyFilterPause(handler, this::getServiceInfo, this::setServiceInfo, () -> {
            if (remapper != null) remapper.filterPaused();
            RemoteButtonLearning.reset();
        }, this::volumeVisible);
        volumeRepeater = new VolumeKeyRepeater(handler, direction -> {
            var audio = getSystemService(android.media.AudioManager.class);
            if (audio != null) audio.adjustSuggestedStreamVolume(direction, android.media.AudioManager.USE_DEFAULT_STREAM_TYPE,
                android.media.AudioManager.FLAG_SHOW_UI);
        });
        if (remapper != null) remapper.close();
        remapper = new RemoteButtonRemapper(this);
        RemoteButtonsBridge.serviceChanged();
    }
    static boolean connected() { return active.get() != null; }
    @Override public void onDestroy() {
        if (volumePause != null) { volumePause.close(); volumePause = null; }
        if (volumeRepeater != null) { volumeRepeater.close(); volumeRepeater = null; }
        systemPackages.clear();
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
        if (volumePause != null && volumePanel(event)) {
            volumeWindowId = event.getWindowId();
            volumePause.event(event, true);
        }
    }

    @Override
    public void onInterrupt() {
        if (remapper != null) remapper.interrupt();
        if (volumeRepeater != null) volumeRepeater.stop();
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (volumeRepeater != null && volumeRepeater.event(event)) return true;
        if (volumePause != null && volumePause.paused()) return false;
        RemoteButtonsBridge.observe(event);
        if (remapper != null && remapper.dismissBlackScreenOnBack(event)) return true;
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
