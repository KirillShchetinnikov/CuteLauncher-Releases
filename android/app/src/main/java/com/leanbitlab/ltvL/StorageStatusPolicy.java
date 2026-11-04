package com.leanbitlab.ltvL;

/** Pure classification. Removable alone does not mean USB (it can be an SD card). */
final class StorageStatusPolicy {
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
        return path != null && path.matches(".*/usb[0-9]+/.*");
    }
    static String blockId(String source) {
        var matcher = java.util.regex.Pattern.compile("(?:public:)?(\\d+)[,:](\\d+)$").matcher(source);
        return matcher.find() ? matcher.group(1) + ":" + matcher.group(2) : null;
    }
}
