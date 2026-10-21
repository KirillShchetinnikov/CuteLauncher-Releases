package com.leanbitlab.ltvL;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.widget.FrameLayout;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Reports the focused Flutter editor to Android TV's IME startup gate. */
final class TvImeEditorBridge {
    private final Activity activity;
    private final MethodChannel channel;
    private EditorProxy proxy;
    private FlutterView flutterView;
    private Integer owner;
    private int previousDescendantFocusability;

    TvImeEditorBridge(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        channel = new MethodChannel(messenger, "cutelauncher/tv_ime_editor");
        channel.setMethodCallHandler((call, result) -> {
            if (!call.method.equals("focus")) { result.notImplemented(); return; }
            Integer editor = call.argument("editor");
            if (editor == null) { result.error("argument", "Missing editor", null); return; }
            if (Boolean.TRUE.equals(call.argument("focused"))) activate(editor);
            else if (editor.equals(owner)) deactivate();
            result.success(null);
        });
    }

    private void activate(Integer editor) {
        flutterView = activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        if (flutterView == null) return;
        owner = editor;
        if (proxy == null) {
            previousDescendantFocusability = flutterView.getDescendantFocusability();
            // Flutter calls requestFocus on its root when showing/restarting input.
            // Android must keep the child editor as the served view in that case.
            flutterView.setDescendantFocusability(ViewGroup.FOCUS_AFTER_DESCENDANTS);
            proxy = new EditorProxy();
            flutterView.addView(proxy, new FrameLayout.LayoutParams(1, 1));
        }
        proxy.requestFocus();
        // Let Flutter attach/set its input client before Android requests the connection.
        proxy.post(() -> {
            if (!editor.equals(owner) || proxy == null) return;
            InputMethodManager imm = activity.getSystemService(InputMethodManager.class);
            imm.restartInput(proxy);
            imm.showSoftInput(proxy, 0);
        });
    }

    private void deactivate() {
        owner = null;
        if (proxy == null) return;
        InputMethodManager imm = activity.getSystemService(InputMethodManager.class);
        imm.hideSoftInputFromWindow(proxy.getWindowToken(), 0);
        flutterView.removeView(proxy);
        flutterView.setDescendantFocusability(previousDescendantFocusability);
        proxy = null;
        flutterView.requestFocus();
    }

    void dispose() {
        deactivate();
        channel.setMethodCallHandler(null);
    }

    private final class EditorProxy extends View {
        EditorProxy() {
            super(activity);
            setFocusable(true);
            setFocusableInTouchMode(true);
            setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
            setAlpha(0);
        }
        @Override public boolean onCheckIsTextEditor() { return owner != null; }
        @Override public InputConnection onCreateInputConnection(EditorInfo info) {
            return owner != null ? flutterView.onCreateInputConnection(info) : null;
        }
        @Override public boolean checkInputConnectionProxy(View view) { return view == flutterView; }
    }
}
