package com.leanbitlab.ltvL;

import android.content.Context;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.AtomicFile;
import android.util.Base64;
import java.io.*;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.Map;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;

/** Device-local account, excluded from backup. No plaintext credentials on disk. */
final class CloudAccountStore {
    private static final Object LOCK=new Object();
    static final String ALIAS="cutelauncher_cloud_account";
    final File path;
    private final String alias;
    CloudAccountStore(Context context) { this(new File(context.getNoBackupFilesDir(),"cloud/account"),ALIAS); }
    CloudAccountStore(File path,String alias) { this.path=path; this.alias=alias; }
    static String directory(String value) throws Exception {
        if(value==null || value.length()>2048 || value.isBlank()) throw new IllegalArgumentException();
        URI uri=new URI(value);
        if(!"https".equals(uri.getScheme()) || uri.getHost()==null || uri.getHost().isEmpty()
            || uri.getRawUserInfo()!=null || uri.getRawQuery()!=null || uri.getRawFragment()!=null
            || uri.getPort()==0 || uri.getPort()>65535 || !uri.getPath().startsWith("/")) throw new IllegalArgumentException();
        if(!uri.getRawPath().endsWith("/")) uri=new URI(value+"/");
        return uri.toASCIIString();
    }
    static void validate(String user,String password) {
        if(user==null || password==null || user.isBlank() || user.length()>256 || user.contains(":")
            || user.chars().anyMatch(c -> c<32 || c==127) || password.isEmpty() || password.length()>4096
            || password.chars().anyMatch(c -> c<32 || c==127)) throw new IllegalArgumentException();
    }
    private SecretKey key(boolean create) throws Exception {
        KeyStore store=KeyStore.getInstance("AndroidKeyStore"); store.load(null);
        if(!store.containsAlias(alias)) {
            if(!create) throw new GeneralSecurityException("Account key unavailable");
            KeyGenerator generator=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());
            generator.generateKey();
        }
        return (SecretKey)store.getKey(alias,null);
    }
    private JSONObject load() throws Exception {
        if(!path.exists() && !new File(path+".bak").exists()) return null;
        AtomicFile file=new AtomicFile(path);
        try(DataInputStream input=new DataInputStream(file.openRead())) {
            if(input.readInt()!=1) throw new IOException("Account format unavailable");
            int nonceSize=input.readInt(); if(nonceSize!=12) throw new IOException("Invalid account framing");
            byte[] nonce=new byte[nonceSize]; input.readFully(nonce);
            int size=input.readInt(); if(size<16 || size>32784) throw new IOException("Invalid account framing");
            byte[] encrypted=new byte[size]; input.readFully(encrypted);
            if(input.read()!=-1) throw new IOException("Invalid account framing");
            Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE,key(false),new GCMParameterSpec(128,nonce));
            byte[] clear=cipher.doFinal(encrypted);
            try {
                JSONObject data=new JSONObject(new String(clear,StandardCharsets.UTF_8));
                if(data.length()!=3) throw new IOException("Invalid account payload");
                directory(data.getString("url")); validate(data.getString("user"),data.getString("password"));
                return data;
            } finally { Arrays.fill(clear,(byte)0); }
        }
    }
    Map<String,Object> info() throws Exception {
        synchronized(LOCK) {
            JSONObject data=load();
            return data==null ? Map.of("configured",false,"url","","user","")
                : Map.of("configured",true,"url",data.getString("url"),"user",data.getString("user"));
        }
    }
    Map<String,String> authorization() throws Exception {
        synchronized(LOCK) {
            JSONObject data=load(); if(data==null) throw new IllegalStateException("Account not configured");
            byte[] bytes=(data.getString("user")+":"+data.getString("password")).getBytes(StandardCharsets.UTF_8);
            try { return Map.of("url",data.getString("url"),"authorization","Basic "+Base64.encodeToString(bytes,Base64.NO_WRAP)); }
            finally { Arrays.fill(bytes,(byte)0); }
        }
    }
    void save(String url,String user,String password) throws Exception {
        synchronized(LOCK) {
            url=directory(url); validate(user,password);
            JSONObject data=new JSONObject(); data.put("url",url); data.put("user",user); data.put("password",password);
            byte[] clear=data.toString().getBytes(StandardCharsets.UTF_8);
            if(clear.length>32768) { Arrays.fill(clear,(byte)0); throw new IllegalArgumentException(); }
            Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding"); byte[] encrypted;
            try { cipher.init(Cipher.ENCRYPT_MODE,key(true)); encrypted=cipher.doFinal(clear); }
            finally { Arrays.fill(clear,(byte)0); }
            File parent=path.getParentFile(); if(!parent.isDirectory() && !parent.mkdirs()) throw new IOException("Account directory unavailable");
            AtomicFile file=new AtomicFile(path); FileOutputStream stream=file.startWrite();
            try {
                DataOutputStream output=new DataOutputStream(stream); output.writeInt(1);
                output.writeInt(cipher.getIV().length); output.write(cipher.getIV());
                output.writeInt(encrypted.length); output.write(encrypted); output.flush(); file.finishWrite(stream);
            } catch(Exception error) { file.failWrite(stream); throw error; }
        }
    }
    void disconnect() throws Exception {
        synchronized(LOCK) {
            new AtomicFile(path).delete();
            if(path.exists() || new File(path+".bak").exists() || new File(path+".new").exists()) throw new IOException("Unable to remove account");
            KeyStore store=KeyStore.getInstance("AndroidKeyStore"); store.load(null); store.deleteEntry(alias);
        }
    }
}
