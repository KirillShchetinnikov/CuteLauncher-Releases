package com.leanbitlab.ltvL;

final class RemoteAdbCommand {
    static String bounded(String script) {
        // Quote the script as one argument and keep its output out of the ADB client.
        return "/system/bin/timeout -k 1s 8s /system/bin/sh -c '"
            + script.replace("'", "'\\''") + "' >/dev/null 2>&1";
    }
}
