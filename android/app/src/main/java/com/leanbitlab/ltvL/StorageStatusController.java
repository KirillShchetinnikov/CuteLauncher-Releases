package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.PowerManager;
import android.os.storage.StorageManager;
import android.os.storage.StorageVolume;
import android.provider.Settings;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.HashMap;
import java.util.Map;

/** Runs on the shared I/O executor. No shell, root, network probes or storage permissions. */
final class StorageStatusController {
    static final ComponentName NAS = new ComponentName("tv.formuler.service.networkstorage.real",
            "tv.formuler.service.networkstorage.MainActivity");
    private final Context context;
    StorageStatusController(Context context) { this.context = context; }

    boolean nasSupported() {
        try {
            var info = context.getPackageManager().getActivityInfo(NAS, 0);
            return info.enabled && info.applicationInfo.enabled && info.exported &&
                    (info.permission == null || context.checkSelfPermission(info.permission) == PackageManager.PERMISSION_GRANTED);
        } catch (PackageManager.NameNotFoundException | RuntimeException unavailable) { return false; }
    }

    Map<String, Object> snapshot() {
        var state = new HashMap<String, Object>();
        var power = context.getSystemService(PowerManager.class);
        boolean screenOn = power == null || power.isInteractive();
        state.put("screenOn", screenOn);
        if (!screenOn) return state;
        boolean supported = nasSupported(), nas = false, usb = false;
        var storage = context.getSystemService(StorageManager.class);
        if (storage != null) {
            // OEM VolumeInfo provides a disk-level USB flag. Hidden APIs are optional:
            // newer systems may block them; public volumes + mount table remain below.
            try {
                var volumes = (java.util.List<?>) StorageManager.class.getMethod("getVolumes").invoke(storage);
                for (var volume : volumes) {
                    if (!(Boolean) volume.getClass().getMethod("isMountedReadable").invoke(volume)) continue;
                    var path = (File) volume.getClass().getMethod("getPath").invoke(volume);
                    boolean network = path != null && StorageStatusPolicy.nasPath(path.getPath());
                    nas |= network;
                    var disk = volume.getClass().getMethod("getDisk").invoke(volume);
                    if (!network && disk != null) usb |= (Boolean) disk.getClass().getMethod("isUsb").invoke(disk);
                }
            } catch (ReflectiveOperationException | RuntimeException unavailable) { /* Optional OEM metadata. */ }
            try {
                for (StorageVolume volume : storage.getStorageVolumes()) {
                    if (volume.isPrimary() || !StorageStatusPolicy.mounted(volume.getState())) continue;
                    File path = null;
                    if (Build.VERSION.SDK_INT >= 30) path = volume.getDirectory();
                    else {
                        try { path = (File) StorageVolume.class.getMethod("getPathFile").invoke(volume); }
                        catch (ReflectiveOperationException | RuntimeException unavailable) { /* Mount table below. */ }
                    }
                    nas |= path != null && StorageStatusPolicy.nasPath(path.getPath());
                    if (path == null || !StorageStatusPolicy.nasPath(path.getPath())) {
                        try {
                            String id = StorageStatusPolicy.blockId((String) StorageVolume.class.getMethod("getId").invoke(volume));
                            if (id != null) usb |= StorageStatusPolicy.usbPath(new File("/sys/dev/block/" + id).getCanonicalPath());
                        } catch (ReflectiveOperationException | java.io.IOException | RuntimeException unavailable) { /* Mount table below. */ }
                    }
                }
            } catch (RuntimeException unavailable) { /* Mount table below. */ }
        }
        // Includes CIFS mounts that OEMs omit from the public StorageVolume API.
        // Read a bounded proc table, never the contents or capacity of a remote share.
        try (var reader = new BufferedReader(new FileReader("/proc/mounts"))) {
            String line;
            int count = 0, bytes = 0;
            while (count++ < 2048 && (line = reader.readLine()) != null && (bytes += line.length()) < 262144) {
                String[] fields = line.split(" +");
                if (fields.length < 3) continue;
                nas |= StorageStatusPolicy.nasMount(fields[1], fields[2]);
                if (StorageStatusPolicy.nasMount(fields[1], fields[2])) continue;
                String id = StorageStatusPolicy.blockId(fields[0]);
                if (id != null && (fields[1].startsWith("/mnt/media_rw/") || fields[1].startsWith("/storage/"))) {
                    usb |= StorageStatusPolicy.usbPath(new File("/sys/dev/block/" + id).getCanonicalPath());
                }
            }
        } catch (java.io.IOException | RuntimeException unavailable) { /* Unknown stays hidden. */ }
        state.put("nasSupported", supported);
        state.put("nas", supported && nas);
        state.put("usb", usb);
        return state;
    }

    boolean open(boolean network) {
        if (network) return nasSupported() && launch(new Intent().setComponent(NAS));
        // Public storage settings first; TV firmwares may implement only one action.
        return launch(new Intent(Settings.ACTION_MEMORY_CARD_SETTINGS)) ||
                launch(new Intent(Settings.ACTION_INTERNAL_STORAGE_SETTINGS));
    }
    private boolean launch(Intent intent) {
        try { context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); return true; }
        catch (RuntimeException unavailable) { return false; }
    }
}
