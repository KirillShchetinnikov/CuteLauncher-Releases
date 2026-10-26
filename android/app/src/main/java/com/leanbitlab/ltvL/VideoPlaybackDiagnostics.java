package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Process;
import java.io.File;
import java.io.RandomAccessFile;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

/** Read only this process's recent media errors; no ADB, root or READ_LOGS permission. */
final class VideoPlaybackDiagnostics {
    static String collect(Context context) {
        File temporary = null;
        java.lang.Process reader = null;
        try {
            temporary = File.createTempFile("video-log-", ".tmp", context.getCacheDir());
            reader = new ProcessBuilder("logcat", "-d", "-t", "160", "--pid=" + Process.myPid(),
                "-v", "threadtime", "ExoPlayerImplInternal:W", "MediaCodec:E", "CCodec:E",
                "ACodec:E", "MediaCodecVideoRenderer:W", "*:S")
                .redirectErrorStream(true).redirectOutput(temporary).start();
            if (!reader.waitFor(2, TimeUnit.SECONDS)) {
                reader.destroyForcibly();
                return "Media log collection timed out";
            }
            if (reader.exitValue() != 0) return "Media log unavailable on this firmware";
            try (RandomAccessFile input = new RandomAccessFile(temporary, "r")) {
                int count = (int) Math.min(input.length(), 8192);
                if (count == 0) return "No recent media errors in application process";
                input.seek(input.length() - count);
                byte[] bytes = new byte[count];
                input.readFully(bytes);
                return "GL texture compatibility: "
                    + io.flutter.embedding.engine.renderer.FlutterRenderer.debugForceSurfaceProducerGlTextures
                    + "\n" + new String(bytes, StandardCharsets.UTF_8);
            }
        } catch (Exception ignored) {
            return "Media log unavailable on this firmware";
        } finally {
            if (reader != null && reader.isAlive()) reader.destroyForcibly();
            if (temporary != null) temporary.delete();
        }
    }
}
