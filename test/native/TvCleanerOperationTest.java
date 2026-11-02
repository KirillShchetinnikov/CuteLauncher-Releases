package com.leanbitlab.ltvL;
import java.util.*;
public final class TvCleanerOperationTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) throws Exception {
        var fake = new TvCleanerRecoveryTest.Fake();
        var names = List.of("org.example.first", "org.example.second", "org.example.third");
        names.forEach(name -> fake.actual.put(name, 1));
        var device = new TvCleanerRecovery.Device() {
            public int state(String name) { return fake.state(name); }
            public void set(String name, int state) throws Exception {
                fake.set(name, state);
                if (name.equals(names.get(1))) throw new Exception("Disconnected after mutation");
            }
        };
        var result = TvCleanerOperation.apply(names, 3, fake, device);
        check(result.failed() && result.rows().size() == 3);
        check(result.rows().get(0).get("status").equals("changed"));
        check(result.rows().get(1).get("status").equals("failed"));
        check(result.rows().get(1).get("reason").equals("command"));
        check(result.rows().get(1).get("afterState").equals(3));
        check(result.rows().get(2).get("status").equals("notAttempted"));
        check(fake.actual.get(names.get(2)) == 1 && fake.persisted.size() == 2);
        fake.restart(); TvCleanerRecovery.restore(fake, fake);
        check(fake.actual.values().stream().allMatch(mode -> mode == 1));
        fake.failWrite = true;
        result = TvCleanerOperation.apply(names, 3, fake, fake);
        check(result.rows().get(0).get("reason").equals("journal"));
        check(fake.actual.get(names.get(0)) == 1);
        fake.failWrite = false; fake.ignoreCommand = true;
        result = TvCleanerOperation.apply(names, 3, fake, fake);
        check(result.rows().get(0).get("reason").equals("verify"));
        fake.ignoreCommand = false;
        result = TvCleanerOperation.restore(Map.of(names.get(0), 3, "org.absent.app", 1), Set.copyOf(names),
                Set.of(names.get(0)), fake, fake);
        check(!result.failed() && result.skipped() == 2);
        check(result.rows().stream().anyMatch(row -> row.get("status").equals("skippedProtected")));
        check(result.rows().stream().anyMatch(row -> row.get("status").equals("skippedMissing")));
        System.out.println("TvCleanerOperationTest passed");
    }
}
