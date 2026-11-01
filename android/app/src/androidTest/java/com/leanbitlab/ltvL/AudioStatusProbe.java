package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.os.Bundle;
import android.media.AudioManager;
import org.json.JSONObject;

/** Read-only device assertions against the production controller. Never changes volume or routing. */
public final class AudioStatusProbe extends Instrumentation {
    private String expected;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); expected = args.getString("expected"); start();
    }
    @Override public void onStart() {
        var report = new Bundle();
        try {
            var context = getTargetContext();
            var state = new AudioStatusController(context).snapshot();
            if (!Boolean.TRUE.equals(state.get("screenOn"))) throw new AssertionError("Screen must be on for this check");
            if (expected == null || !java.util.List.of(expected).equals(state.get("outputs")))
                throw new AssertionError("Expected " + expected + ", got " + state);
            var audio = context.getSystemService(AudioManager.class);
            if (!Boolean.valueOf(audio.isStreamMute(AudioManager.STREAM_MUSIC)).equals(state.get("muted")))
                throw new AssertionError("Mute differs from Android");
            if (!audio.isVolumeFixed()) {
                int percent = Math.round(100f * audio.getStreamVolume(AudioManager.STREAM_MUSIC)
                    / audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC));
                if (!Integer.valueOf(percent).equals(state.get("percent"))) throw new AssertionError("Level differs from Android");
            }
            report.putString("audio", new JSONObject(state).toString());
            report.putString("stream", "PASS: read-only production snapshot " + new JSONObject(state)); finish(-1, report);
        } catch (Throwable failure) {
            report.putString("stream", "FAIL: " + failure); finish(0, report);
        }
    }
}
