package com.leanbitlab.ltvL;

import android.content.Context;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.AtomicFile;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;

/** Local token bound to the exact HTTPS base URL, including its path. */
final class WeatherTokenBridge {
    private static final String ALIAS = "cutelauncher_weather_token";
    private static final Object LOCK = new Object();
    private final AtomicFile file;

    private WeatherTokenBridge(Context context) {
        file = new AtomicFile(new File(context.getNoBackupFilesDir(), "weather-token"));
    }

    static void register(Context context, BinaryMessenger messenger) {
        WeatherTokenBridge store = new WeatherTokenBridge(context.getApplicationContext());
        new MethodChannel(messenger, "cutelauncher/weather_token",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
            .setMethodCallHandler((call, result) -> {
                try {
                    String server = call.argument("server");
                    if (server == null || server.isEmpty() || server.length() > 4096) throw new IllegalArgumentException();
                    synchronized (LOCK) {
                        switch (call.method) {
                            case "read" -> result.success(store.read(server));
                            case "has" -> result.success(store.read(server) != null);
                            case "save" -> {
                                store.save(server, call.argument("token"));
                                result.success(null);
                            }
                            default -> result.notImplemented();
                        }
                    }
                } catch (Exception ignored) {
                    result.error("unavailable", "Weather token storage unavailable", null);
                }
            });
    }

    private static SecretKey key(boolean create) throws Exception {
        KeyStore store = KeyStore.getInstance("AndroidKeyStore");
        store.load(null);
        if (!store.containsAlias(ALIAS)) {
            if (!create) throw new IOException();
            KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());
            generator.generateKey();
        }
        return (SecretKey) store.getKey(ALIAS, null);
    }

    private String read(String server) throws Exception {
        try (DataInputStream input = new DataInputStream(file.openRead())) {
            if (input.readInt() != 1) throw new IOException();
            byte[] nonce = new byte[12];
            input.readFully(nonce);
            int size = input.readInt();
            if (size < 16 || size > 32768) throw new IOException();
            byte[] encrypted = new byte[size];
            input.readFully(encrypted);
            if (input.read() != -1) throw new IOException();
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key(false), new GCMParameterSpec(128, nonce));
            byte[] clear = cipher.doFinal(encrypted);
            try {
                JSONObject data = new JSONObject(new String(clear, StandardCharsets.UTF_8));
                return server.equals(data.getString("server")) ? data.getString("token") : null;
            } finally {
                Arrays.fill(clear, (byte) 0);
            }
        } catch (FileNotFoundException absent) {
            if (file.getBaseFile().exists() || new File(file.getBaseFile() + ".bak").exists()) throw absent;
            return null;
        }
    }

    private void save(String server, String token) throws Exception {
        if (token == null || token.length() > 1024) throw new IllegalArgumentException();
        if (token.isEmpty()) {
            file.delete();
            if (file.getBaseFile().exists() || new File(file.getBaseFile() + ".bak").exists()
                || new File(file.getBaseFile() + ".new").exists()) throw new IOException();
            return;
        }
        byte[] clear = new JSONObject().put("server", server).put("token", token).toString().getBytes(StandardCharsets.UTF_8);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        byte[] encrypted;
        try {
            cipher.init(Cipher.ENCRYPT_MODE, key(true));
            encrypted = cipher.doFinal(clear);
        } finally {
            Arrays.fill(clear, (byte) 0);
        }
        FileOutputStream stream = file.startWrite();
        try {
            DataOutputStream output = new DataOutputStream(stream);
            output.writeInt(1);
            output.write(cipher.getIV());
            output.writeInt(encrypted.length);
            output.write(encrypted);
            output.flush();
            file.finishWrite(stream);
        } catch (Exception error) {
            file.failWrite(stream);
            throw error;
        }
    }
}
