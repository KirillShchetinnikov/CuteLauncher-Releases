package com.leanbitlab.ltvL;

import java.net.HttpURLConnection;
import java.net.URI;

/** One POST, fixed body, no application retry and no redirect forwarding of the secret URL. */
final class RemoteWebhookClient {
    static boolean post(String url, int timeoutMs) throws Exception {
        if (!RemoteMappingConfiguration.webhook(url)) throw new IllegalArgumentException();
        HttpURLConnection connection = (HttpURLConnection)new URI(url).toURL().openConnection();
        try {
            connection.setConnectTimeout(timeoutMs); connection.setReadTimeout(timeoutMs);
            connection.setInstanceFollowRedirects(false);
            connection.setRequestMethod("POST"); connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setFixedLengthStreamingMode(2);
            try (java.io.OutputStream body = connection.getOutputStream()) { body.write(new byte[]{'{', '}'}); }
            int code = connection.getResponseCode();
            return code >= 200 && code < 300;
        } finally { connection.disconnect(); }
    }
}
