package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import java.io.File;
import java.nio.file.Files;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Map;

/** Uses its own temporary file and key alias; never reads or changes the real account. */
public final class CloudAccountProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    private static void require(boolean value, String label) { if (!value) throw new AssertionError(label); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        CloudAccountStore account = null;
        File folder = null;
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"), "Emulator only");
            String alias = "cutelauncher_cloud_probe_" + System.nanoTime();
            folder = new File(getTargetContext().getCacheDir(), alias);
            require(folder.mkdir(), "Private probe directory");
            account = new CloudAccountStore(new File(folder, "account"), alias);
            require(account.info().get("configured").equals(false), "Initially empty");
            String url = "https://example.test/remote.php/dav/files/u%20ser/backup/";
            account.save(url, "probe-user", "probe-password-dummy-only");
            Map<String,Object> info = new CloudAccountStore(account.path, alias).info();
            require(info.get("configured").equals(true) && info.get("url").equals(url), "Persistence and escaped URL");
            require(!info.containsKey("password") && !info.containsKey("authorization"), "Info excludes secrets");
            byte[] encrypted = Files.readAllBytes(account.path.toPath());
            require(!new String(encrypted, StandardCharsets.ISO_8859_1).contains("probe-password"), "Encrypted disk data");
            KeyStore keys = KeyStore.getInstance("AndroidKeyStore"); keys.load(null);
            require(keys.getKey(alias, null).getEncoded() == null, "Key nonexportable");
            require(account.authorization().get("authorization").startsWith("Basic "), "Authorization available");
            Files.move(account.path.toPath(), new File(account.path + ".bak").toPath());
            require(account.info().get("configured").equals(true), "Interrupted atomic write recovered");
            encrypted[encrypted.length - 1] ^= 1;
            Files.write(account.path.toPath(), encrypted);
            boolean rejected = false;
            try { account.authorization(); } catch (Exception expected) { rejected = true; }
            require(rejected, "Tampered ciphertext rejected");
            account.save(url, "probe-user", "replacement-dummy");
            keys.deleteEntry(alias);
            rejected = false;
            try { account.info(); } catch (Exception expected) { rejected = true; }
            require(rejected && account.path.exists(), "Missing key fails without silently resetting account");
            account.disconnect();
            require(account.info().get("configured").equals(false) && !keys.containsAlias(alias), "Disconnect removes account and key");
            for (String bad : new String[]{"http://example.test/", "https://user:secret@example.test/", "https://example.test/?token=1", "https://example.test/#fragment"}) {
                rejected = false;
                try { account.save(bad, "probe-user", "dummy"); } catch (Exception expected) { rejected = true; }
                require(rejected, "Unsafe URL rejected");
            }
            report.putString("result", "PASS: encrypted persistence, atomic recovery, tamper/missing-key rejection, disconnect, URL validation");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error.getClass().getSimpleName() + ": " + error.getMessage());
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            if (account != null) try { account.disconnect(); } catch (Exception ignored) { }
            if (folder != null) folder.delete();
        }
    }
}
