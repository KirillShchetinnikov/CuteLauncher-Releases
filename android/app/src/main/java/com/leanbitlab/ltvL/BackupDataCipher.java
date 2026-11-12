package com.leanbitlab.ltvL;

import java.io.*;
import java.nio.file.Files;
import java.security.SecureRandom;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

/** Versioned whole-file encryption. Authentication succeeds before replacing input. */
final class BackupDataCipher {
    static final byte[] MAGIC = {'C','U','T','E','E','N','C','1'};
    static final int ITERATIONS = 600_000;
    static final long LIMIT = 64L * 1024 * 1024;
    static boolean encrypted(File file) throws IOException {
        if(file.length()<8) return false;
        try (DataInputStream in = new DataInputStream(new FileInputStream(file))) { byte[] magic=new byte[8];in.readFully(magic);return Arrays.equals(magic, MAGIC); }
    }
    static void transform(File file, String password, boolean encrypt) throws Exception {
        if (!encrypt && !encrypted(file)) return;
        if (encrypt && password.isEmpty()) return;
        if (password.isEmpty() || password.length() > 1024 || file.length() > LIMIT) throw new IllegalArgumentException();
        File pending = new File(file.getPath() + ".crypt");
        byte[] salt = new byte[16], nonce = new byte[12];
        try (DataInputStream in = new DataInputStream(new FileInputStream(file));
             OutputStream out = new FileOutputStream(pending)) {
            if (encrypt) {
                SecureRandom random = new SecureRandom(); random.nextBytes(salt); random.nextBytes(nonce);
            } else {
                byte[] magic=new byte[8];in.readFully(magic);
                if (!Arrays.equals(magic, MAGIC) || in.readInt() != ITERATIONS) throw new IllegalArgumentException();
                in.readFully(salt); in.readFully(nonce);
            }
            PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATIONS, 256);
            byte[] key;
            try { key = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded(); }
            finally { spec.clearPassword(); }
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            try { cipher.init(encrypt ? Cipher.ENCRYPT_MODE : Cipher.DECRYPT_MODE, new SecretKeySpec(key,"AES"), new GCMParameterSpec(128, nonce)); }
            finally { Arrays.fill(key, (byte)0); }
            cipher.updateAAD(MAGIC);
            if (encrypt) { DataOutputStream header = new DataOutputStream(out); header.write(MAGIC); header.writeInt(ITERATIONS); header.write(salt); header.write(nonce); }
            byte[] buffer = new byte[64 * 1024]; int count;
            while ((count = in.read(buffer)) != -1) { byte[] chunk = cipher.update(buffer,0,count); if(chunk != null) out.write(chunk); }
            out.write(cipher.doFinal()); Arrays.fill(buffer, (byte)0);
        } catch (Exception failure) { Files.deleteIfExists(pending.toPath()); throw failure; }
        if (pending.length() > LIMIT) { Files.deleteIfExists(pending.toPath()); throw new IOException(); }
        try { Files.move(pending.toPath(), file.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING); }
        finally { Files.deleteIfExists(pending.toPath()); }
    }
}
