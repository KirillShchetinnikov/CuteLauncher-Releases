/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.media.tv.TvInputManager;
import android.media.tv.TvInputInfo;
import android.media.tv.TvContract;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
/** Native input snapshots, switching and lifecycle-owned connection events. */
final class TvInputBridge implements EventChannel.StreamHandler, AutoCloseable {
    private final Context context;

    private final EventChannel events;
    private TvInputManager listeningManager;
    private EventChannel.EventSink sink;
    private final TvInputManager.TvInputCallback callback = new TvInputManager.TvInputCallback() {
        @Override public void onInputAdded(String id) { changed(); }
        @Override public void onInputRemoved(String id) { changed(); }
        @Override public void onInputUpdated(String id) { changed(); }
        @Override public void onInputStateChanged(String id, int state) { changed(); }
        @Override public void onTvInputInfoUpdated(TvInputInfo info) { changed(); }
    };

    TvInputBridge(Context context) { this.context = context; events = null; }

    TvInputBridge(Context context, BinaryMessenger messenger) {
        this.context = context;
        events = new EventChannel(messenger, "me.efesser.flauncher/event_tv_inputs");
        events.setStreamHandler(this);
    }

    private void changed() { if (sink != null) sink.success(true); }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        sink = events;
        try {
            TvInputManager manager = (TvInputManager) context.getSystemService(Context.TV_INPUT_SERVICE);
            if (manager != null) {
                manager.registerCallback(callback, new Handler(Looper.getMainLooper()));
                listeningManager = manager;
            }
        } catch (RuntimeException ignored) { /* Snapshot remains available on restricted firmware. */ }
    }

    @Override public void onCancel(Object arguments) {
        sink = null;
        if (listeningManager != null) {
            try { listeningManager.unregisterCallback(callback); }
            catch (RuntimeException ignored) { /* OEM service may have stopped. */ }
            listeningManager = null;
        }
    }

    @Override public void close() { onCancel(null); if (events != null) events.setStreamHandler(null); }

    List<Map<String, Object>> getTvInputs() {
        List<Map<String, Object>> result = new ArrayList<>();
        try {
            TvInputManager manager = (TvInputManager) context.getSystemService(Context.TV_INPUT_SERVICE);
            if (manager != null) {
                List<TvInputInfo> inputs = manager.getTvInputList();
                for (TvInputInfo input : inputs) {
                    if (input.isPassthroughInput()) {
                        Map<String, Object> map = new HashMap<>();
                        map.put("id", input.getId());
                        CharSequence label = input.loadLabel(context);
                        map.put("label", label != null ? label.toString() : input.getId());
                        map.put("type", input.getType());
                        try { map.put("state", manager.getInputState(input.getId())); }
                        catch (RuntimeException ignored) { /* Unknown is not disconnected. */ }
                        if (input.getType() == TvInputInfo.TYPE_HDMI) {
                            if (input.getParentId() != null) map.put("parentId", input.getParentId());
                            try {
                                CharSequence custom = input.loadCustomLabel(context);
                                if (custom != null) map.put("customLabel", custom.toString());
                            } catch (RuntimeException ignored) { /* Keep the system label if OEM settings are unavailable. */ }
                        }
                        result.add(map);
                    }
                }
            }
        } catch (Exception e) {
            // TIF might not be supported or initialized on emulator
        }
        return result;
    }

    boolean launchTvInput(String inputId) {
        try {
            Uri uri = TvContract.buildChannelUriForPassthroughInput(inputId);
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setData(uri);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return tryStartActivity(intent);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean tryStartActivity(Intent intent) {
        try { context.startActivity(intent); return true; }
        catch (Exception ignored) { return false; }
    }
}
