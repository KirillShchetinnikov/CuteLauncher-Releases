package com.leanbitlab.ltvL;

final class RemoteAdbCommand {
    static String saveScreenshot(AdbBridge.Shell shell) throws Exception {
        String stamp = java.time.LocalDateTime.now().format(
            java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss-SSS", java.util.Locale.ROOT));
        String name = "CuteLauncher_" + stamp + ".png";
        // Publish the final name only after screencap has written the whole PNG.
        shell.execute(bounded("mkdir -p /sdcard/Download && cd /sdcard/Download || exit 1\n"
            + "tmp=$(mktemp .cutelauncher-XXXXXX) || exit 1\n"
            + "trap 'rm -f \"$tmp\"' EXIT\n"
            + "test ! -e " + name + " && screencap -p > \"$tmp\" && test -s \"$tmp\" && mv \"$tmp\" " + name));
        return name;
    }

    static String bounded(String script) {
        // Quote the script as one argument and keep its output out of the ADB client.
        return "/system/bin/timeout -k 1s 8s /system/bin/sh -c '"
            + script.replace("'", "'\\''") + "' >/dev/null 2>&1";
    }
}
