package com.leanbitlab.ltvL;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/** Portable encryption key is random, never derived from an account password. */
final class SyncCipher {
    static String generate() {
        byte[] key = new byte[32]; new SecureRandom().nextBytes(key);
        StringBuilder value = new StringBuilder(64);
        for (byte b : key) value.append(String.format("%02x", b & 255));
        return value.toString();
    }
    static byte[] key(String text) {
        if (text == null || !text.matches("[a-fA-F0-9]{64}")) throw new IllegalArgumentException("Invalid sync key");
        byte[] bytes = new byte[32];
        for (int i = 0; i < 32; i++) bytes[i] = (byte)Integer.parseInt(text.substring(i * 2, i * 2 + 2), 16);
        return bytes;
    }
    static String seal(String key, String record, String clear) throws Exception {
        byte[] nonce = new byte[12]; new SecureRandom().nextBytes(nonce);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key(key), "AES"), new GCMParameterSpec(128, nonce));
        cipher.updateAAD(("CuteLauncher.sync.v1:" + record).getBytes(StandardCharsets.UTF_8));
        return "1." + Base64.getEncoder().encodeToString(nonce) + "." +
            Base64.getEncoder().encodeToString(cipher.doFinal(clear.getBytes(StandardCharsets.UTF_8)));
    }
    static String open(String key, String record, String envelope) throws Exception {
        if (envelope == null || envelope.length() > 2_000_000) throw new IllegalArgumentException("Invalid sync envelope");
        String[] fields = envelope.split("\\.", -1);
        if (fields.length != 3 || !fields[0].equals("1")) throw new IllegalArgumentException("Invalid sync envelope");
        byte[] nonce = Base64.getDecoder().decode(fields[1]);
        if (nonce.length != 12) throw new IllegalArgumentException("Invalid sync nonce");
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key(key), "AES"), new GCMParameterSpec(128, nonce));
        cipher.updateAAD(("CuteLauncher.sync.v1:" + record).getBytes(StandardCharsets.UTF_8));
        return new String(cipher.doFinal(Base64.getDecoder().decode(fields[2])), StandardCharsets.UTF_8);
    }
}
