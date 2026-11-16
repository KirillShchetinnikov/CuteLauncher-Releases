package com.leanbitlab.ltvL;

import java.util.regex.Pattern;

/** Pure classification. Removable alone does not mean USB (it can be an SD card). */
final class StorageStatusPolicy {
    private static final Pattern USB_PATH = Pattern.compile(".*/usb[0-9]+/.*");
    private static final Pattern BLOCK_ID = Pattern.compile("(?:public:)?(\\d+)[,:](\\d+)$");

    static boolean mounted(String state) {
        return "mounted".equals(state) || "mounted_ro".equals(state);
    }
    static boolean nasPath(String path) {
        return path != null && (path.startsWith("/mnt/cifs/") || path.startsWith("/mnt/smb/"));
    }
    static boolean nasMount(String path, String type) {
        return nasPath(path) || "cifs".equals(type) || "smb3".equals(type);
    }
    static boolean usbPath(String path) {
        return path != null && USB_PATH.matcher(path).matches();
    }
    static String usbMountBlockId(String source, String mountPath) {
        if (!mountPath.startsWith("/mnt/media_rw/") && !mountPath.startsWith("/storage/")) return null;
        return blockId(source);
    }
    static String blockId(String source) {
        var matcher = BLOCK_ID.matcher(source);
        return matcher.find() ? matcher.group(1) + ":" + matcher.group(2) : null;
    }
}
