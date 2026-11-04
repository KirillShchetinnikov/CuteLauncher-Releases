package com.leanbitlab.ltvL;

public final class BackupDeviceIdentityTest {
    public static void main(String[] args) {
        var first = BackupDeviceIdentity.create("1234567890abcdef", "TCL", "Smart TV Pro");
        var next = BackupDeviceIdentity.create("1234567890ABCDEF", "TCL", "Different model name");
        if (!first.get("id").equals(next.get("id"))) throw new AssertionError("Identity depends on model");
        if (!first.get("id").matches("[a-f0-9]{32}")) throw new AssertionError("Invalid digest");
        if (first.get("id").contains("1234567890abcdef")) throw new AssertionError("Raw identity leaked");
        if (!first.get("label").equals("TCL_Smart_TV_Pro")) throw new AssertionError("Missing model");
        if (BackupDeviceIdentity.create(null, "", "").containsKey("id")) throw new AssertionError("Invented identity");
        if (BackupDeviceIdentity.create("0", "", "").containsKey("id")) throw new AssertionError("Zero identity");
        if (!BackupDeviceIdentity.create(null, "../../", "x".repeat(200)).get("label").matches("[A-Za-z0-9_]{1,64}")) throw new AssertionError("Unsafe label");
        System.out.println("Backup device identity: OK");
    }
}
