package com.leanbitlab.ltvL;

import android.content.Context;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.AtomicFile;
import java.io.*;
import java.security.KeyStore;
import java.nio.charset.StandardCharsets;
import javax.crypto.*;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;

/** Local key, ciphertext cache and rollback journal never enter backups. */
class SyncPrivateStore {
    private final AtomicFile file;
    private static final String ALIAS = "cutelauncher_sync_private";
    SyncPrivateStore(Context c, String name) {
        file = new AtomicFile(new File(c.getNoBackupFilesDir(), "sync-" + name));
    }
    private static SecretKey key(boolean create) throws Exception {
        KeyStore keys = KeyStore.getInstance("AndroidKeyStore"); keys.load(null);
        if (!keys.containsAlias(ALIAS)) {
            if (!create) throw new IOException("Sync key unavailable");
            KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());
            generator.generateKey();
        }
        return (SecretKey)keys.getKey(ALIAS, null);
    }
    JSONObject read() throws Exception {
        try (DataInputStream input = new DataInputStream(file.openRead())) {
            if (input.readInt() != 1) throw new IOException();
            byte[] nonce = new byte[12]; input.readFully(nonce);
            int length = input.readInt(); if (length < 16 || length > 4_194_304) throw new IOException();
            byte[] bytes = new byte[length]; input.readFully(bytes);
            if (input.read() != -1) throw new IOException();
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key(false), new GCMParameterSpec(128, nonce));
            byte[] clear = cipher.doFinal(bytes);
            try { return new JSONObject(new String(clear, StandardCharsets.UTF_8)); }
            finally { java.util.Arrays.fill(clear, (byte)0); }
        } catch (FileNotFoundException absent) {
            if (file.getBaseFile().exists() || new File(file.getBaseFile() + ".bak").exists()) throw absent;
            return new JSONObject();
        }
    }
    void write(JSONObject data) throws Exception {
        byte[] clear = data.toString().getBytes(StandardCharsets.UTF_8);
        if (clear.length > 4_194_288) throw new IOException();
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding"); byte[] encrypted;
        try { cipher.init(Cipher.ENCRYPT_MODE, key(true)); encrypted = cipher.doFinal(clear); }
        finally { java.util.Arrays.fill(clear, (byte)0); }
        FileOutputStream stream = file.startWrite();
        try {
            DataOutputStream output = new DataOutputStream(stream);
            output.writeInt(1); output.write(cipher.getIV()); output.writeInt(encrypted.length); output.write(encrypted);
            output.flush(); file.finishWrite(stream);
        } catch (Exception error) { file.failWrite(stream); throw error; }
    }
    void delete() throws IOException {
        file.delete();
        if (file.getBaseFile().exists() || new File(file.getBaseFile() + ".bak").exists() ||
            new File(file.getBaseFile() + ".new").exists()) throw new IOException();
    }
}
