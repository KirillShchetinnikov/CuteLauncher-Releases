package com.leanbitlab.ltvL;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.WindowManager;
import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;

/** Focusable service window: never starts an Activity or changes the video task. */
final class RemotePanelWindow implements AutoCloseable {
    private final LauncherAccessibilityService service;
    private final Handler main = new Handler(Looper.getMainLooper());
    private FlutterEngine engine;
    private FlutterView view;
    private RemotePanelChannels channels;
    private MethodChannel control;
    private boolean closing, backDown;
    private boolean screenReceiverRegistered;
    private final android.content.BroadcastReceiver screenReceiver = new android.content.BroadcastReceiver() {
        @Override public void onReceive(Context context, android.content.Intent intent) { requestClose(); }
    };
    RemotePanelWindow(LauncherAccessibilityService service) { this.service = service; }
    boolean isOpen() { return engine != null; }
    boolean toggle() {
        if (engine != null) { requestClose(); return true; }
        try {
            closing = false;
            engine = new FlutterEngine(service);
            var messenger = engine.getDartExecutor().getBinaryMessenger();
            channels = new RemotePanelChannels(service, messenger, this::requestClose);
            control = new MethodChannel(messenger, "cutelauncher/remote_panel");
            control.setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "show" -> result.success(true);
                    case "ready" -> { main.removeCallbacks(startTimeout); result.success(null); }
                    case "close" -> { result.success(null); requestClose(); }
                    case "closed" -> { result.success(null); main.post(this::close); }
                    default -> result.notImplemented();
                }
            });
            view = new FlutterView(service, new FlutterTextureView(service));
            view.setBackgroundColor(android.graphics.Color.TRANSPARENT);
            view.attachToFlutterEngine(engine);
            WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN, PixelFormat.TRANSLUCENT);
            params.gravity = Gravity.TOP | Gravity.START;
            params.setTitle("CuteLauncher remote panel");
            service.getSystemService(WindowManager.class).addView(view, params);
            service.registerReceiver(screenReceiver, new android.content.IntentFilter(android.content.Intent.ACTION_SCREEN_OFF));
            screenReceiverRegistered = true;
            engine.getLifecycleChannel().appIsResumed();
            var loader = FlutterInjector.instance().flutterLoader();
            engine.getDartExecutor().executeDartEntrypoint(new DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "remotePanelMain"));
            view.requestFocus();
            main.postDelayed(startTimeout, 15000);
            return true;
        } catch (RuntimeException error) {
            android.util.Log.w("RemotePanel", "Unable to open panel", error);
            close(); return false;
        }
    }
    private final Runnable startTimeout = this::requestClose;
    boolean event(KeyEvent event) {
        if (engine == null && !backDown) return false;
        if (event.getKeyCode() == KeyEvent.KEYCODE_HOME) { requestClose(); return false; }
        if (event.getKeyCode() != KeyEvent.KEYCODE_BACK) return false;
        if (event.getAction() == KeyEvent.ACTION_DOWN) backDown = true;
        if (event.getAction() == KeyEvent.ACTION_UP) {
            backDown = false;
            if (!event.isCanceled() && engine != null && !closing) engine.getNavigationChannel().popRoute();
        }
        return true;
    }
    void requestClose() {
        if (engine == null || closing) return;
        closing = true;
        main.removeCallbacks(startTimeout);
        control.invokeMethod("dispose", null);
        main.postDelayed(this::close, 1500);
    }
    @Override public void close() {
        main.removeCallbacksAndMessages(null);
        if (screenReceiverRegistered) { service.unregisterReceiver(screenReceiver); screenReceiverRegistered = false; }
        if (view != null) {
            try { service.getSystemService(WindowManager.class).removeViewImmediate(view); } catch (RuntimeException ignored) { }
            view.detachFromFlutterEngine(); view = null;
        }
        if (channels != null) { channels.close(); channels = null; }
        if (engine != null) {
            engine.getLifecycleChannel().appIsDetached(); engine.destroy(); engine = null;
        }
        control = null; closing = false; MainActivity.panelClosed();
    }
}
