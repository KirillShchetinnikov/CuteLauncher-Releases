package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import org.json.JSONObject;

/** Checks HTTPS reachability and rejection without credentials; never reads app keys/settings. */
public final class OpenWeatherAccessProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle result = new Bundle();
        StringBuilder report = new StringBuilder();
        var power = (android.os.PowerManager) getTargetContext().getSystemService(android.content.Context.POWER_SERVICE);
        report.append("Screen interactive: ").append(power != null && power.isInteractive()).append('\n');
        report.append("Internet permission: ").append(getTargetContext().checkSelfPermission("android.permission.INTERNET")
            == android.content.pm.PackageManager.PERMISSION_GRANTED).append('\n');
        boolean passed = true;
        for (String endpoint : new String[]{"weather", "forecast"}) {
            HttpURLConnection connection = null;
            try {
                connection = (HttpURLConnection) new URL("https://api.openweathermap.org/data/2.5/" + endpoint
                    + "?lat=55.75&lon=37.62&units=metric").openConnection();
                connection.setConnectTimeout(8000); connection.setReadTimeout(8000);
                connection.setInstanceFollowRedirects(false);
                if (connection.getResponseCode() != 401) throw new AssertionError("Expected missing-key HTTP 401");
                try (var input = connection.getErrorStream()) {
                    if (input == null) throw new AssertionError("Missing error body");
                    byte[] bytes = input.readNBytes(16385);
                    if (bytes.length > 16384) throw new AssertionError("Response too large");
                    if (new JSONObject(new String(bytes, StandardCharsets.UTF_8)).getInt("cod") != 401)
                        throw new AssertionError("Unexpected error schema");
                }
                report.append("PASS ").append(endpoint).append(": HTTPS, HTTP 401, cod 401\n");
            } catch (Throwable error) {
                passed = false;
                // Neither request URI, response body nor credentials are included in the report.
                report.append("FAIL ").append(endpoint).append(": ").append(error.getClass().getSimpleName()).append('\n');
            } finally { if (connection != null) connection.disconnect(); }
        }
        result.putString("stream", "\n" + report);
        finish(passed ? Activity.RESULT_OK : Activity.RESULT_CANCELED, result);
    }
}
