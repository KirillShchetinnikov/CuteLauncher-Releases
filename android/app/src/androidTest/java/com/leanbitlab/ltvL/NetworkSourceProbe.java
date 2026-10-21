package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;

/** Read-only diagnosis of actual endpoint access; does not alter app settings. */
public final class NetworkSourceProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        String[][] sources = {
            {"open-meteo", "https://api.open-meteo.com/v1/forecast?latitude=55.7558&longitude=37.6173&current=temperature_2m,weather_code&timezone=auto"},
            {"bing", "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"},
            {"https-image", "https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg"}
        };
        JSONArray results = new JSONArray(); boolean passed = true;
        for (String[] source : sources) {
            JSONObject item = new JSONObject(); HttpURLConnection connection = null;
            try {
                item.put("source", source[0]);
                connection = (HttpURLConnection) new URL(source[1]).openConnection();
                connection.setConnectTimeout(8000); connection.setReadTimeout(8000);
                int status = connection.getResponseCode(); item.put("http", status);
                if (status != 200) throw new AssertionError("HTTP " + status);
                byte[] body;
                try (var stream = connection.getInputStream(); var bytes = new java.io.ByteArrayOutputStream()) {
                    byte[] buffer = new byte[8192]; int count;
                    while ((count = stream.read(buffer)) != -1) {
                        if (bytes.size() + count > 512 * 1024) throw new AssertionError("Response too large");
                        bytes.write(buffer, 0, count);
                    }
                    body = bytes.toByteArray();
                }
                if (source[0].equals("open-meteo") && !new JSONObject(new String(body, java.nio.charset.StandardCharsets.UTF_8)).has("current"))
                    throw new AssertionError("Forecast fields missing");
                if (source[0].equals("bing") && new JSONObject(new String(body, java.nio.charset.StandardCharsets.UTF_8)).getJSONArray("images").length() == 0)
                    throw new AssertionError("Bing image missing");
                if (source[0].equals("https-image")) {
                    var bitmap = android.graphics.BitmapFactory.decodeByteArray(body, 0, body.length);
                    if (bitmap == null) throw new AssertionError("Image decode failed");
                    bitmap.recycle();
                }
                item.put("result", "PASS").put("bytes", body.length);
            } catch (Throwable failure) {
                passed = false;
                try { item.put("result", "FAIL").put("error", failure.toString()); } catch (Exception ignored) { }
            } finally { if (connection != null) connection.disconnect(); }
            results.put(item);
        }
        Bundle report = new Bundle(); report.putString("stream", "\n" + results + "\n");
        finish(passed ? Activity.RESULT_OK : Activity.RESULT_CANCELED, report);
    }
}
