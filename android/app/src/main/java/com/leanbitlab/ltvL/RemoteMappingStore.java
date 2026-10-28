package com.leanbitlab.ltvL;

import android.content.Context;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.AtomicFile;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.*;
import javax.crypto.*;
import javax.crypto.spec.GCMParameterSpec;
import org.json.*;

/** All mapping data, including webhook secrets, is encrypted and excluded from backup. */
final class RemoteMappingStore {
    private static final Object LOCK = new Object();
    private static final String ALIAS = "cutelauncher_remote_mappings";
    private final AtomicFile file;
    RemoteMappingStore(Context context) {
        file = new AtomicFile(new File(context.getNoBackupFilesDir(), "remote-mappings"));
    }
    private static SecretKey key(boolean create) throws Exception {
        KeyStore store = KeyStore.getInstance("AndroidKeyStore"); store.load(null);
        if (!store.containsAlias(ALIAS)) {
            if (!create) throw new IOException();
            KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());
            generator.generateKey();
        }
        return (SecretKey)store.getKey(ALIAS, null);
    }
    RemoteMappingConfiguration load() throws Exception {
        synchronized (LOCK) {
            byte[] data;
            try (DataInputStream input = new DataInputStream(file.openRead())) {
                if (input.readInt() != 1) throw new IOException();
                byte[] nonce = new byte[12]; input.readFully(nonce);
                int size = input.readInt(); if (size < 16 || size > 1_048_576) throw new IOException();
                byte[] encrypted = new byte[size]; input.readFully(encrypted);
                if (input.read() != -1) throw new IOException();
                Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
                cipher.init(Cipher.DECRYPT_MODE, key(false), new GCMParameterSpec(128, nonce));
                data = cipher.doFinal(encrypted);
            } catch (FileNotFoundException absent) {
                if (file.getBaseFile().exists() || new File(file.getBaseFile() + ".bak").exists()) throw absent;
                return RemoteMappingConfiguration.empty();
            }
            try {
                return decode(new JSONObject(new String(data, StandardCharsets.UTF_8)));
            } finally { Arrays.fill(data, (byte)0); }
        }
    }
    static RemoteMappingConfiguration decode(JSONObject root) throws JSONException {
        JSONArray rows = root.getJSONArray("bindings");
        List<Map<String, Object>> bindings = new ArrayList<>();
        for (int i = 0; i < rows.length(); i++) {
            JSONObject row = rows.getJSONObject(i);
            bindings.add(Map.of("keyCode", row.getInt("keyCode"), "enabled", row.getBoolean("enabled"),
                "action", row.getString("action"), "target", row.getString("target"), "trigger", row.optString("trigger", "press"),
                "name", row.optString("name", "")));
        }
        return RemoteMappingConfiguration.fromMap(Map.of("enabled", root.getBoolean("enabled"), "bindings", bindings));
    }
    void save(RemoteMappingConfiguration configuration) throws Exception {
        synchronized (LOCK) {
            byte[] data = new JSONObject(configuration.toMap()).toString().getBytes(StandardCharsets.UTF_8);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            byte[] encrypted;
            try { cipher.init(Cipher.ENCRYPT_MODE, key(true)); encrypted = cipher.doFinal(data); }
            finally { Arrays.fill(data, (byte)0); }
            FileOutputStream stream = file.startWrite();
            try {
                DataOutputStream output = new DataOutputStream(stream);
                output.writeInt(1); output.write(cipher.getIV()); output.writeInt(encrypted.length); output.write(encrypted);
                output.flush(); file.finishWrite(stream);
            } catch (Exception error) { file.failWrite(stream); throw error; }
        }
    }
}
