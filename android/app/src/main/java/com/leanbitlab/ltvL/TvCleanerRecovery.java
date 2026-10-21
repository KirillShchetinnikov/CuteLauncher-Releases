package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Write-ahead recovery, independent of Android so interruption windows can be tested. */
final class TvCleanerRecovery {
    interface Journal {
        Integer original(String name) throws Exception;
        void remember(String name, int fallback) throws Exception;
        Set<String> pending() throws Exception;
        void forget(String name) throws Exception;
        void persist() throws Exception;
    }
    interface Device {
        int state(String name) throws Exception;
        void set(String name, int state) throws Exception;
    }
    static int apply(List<String> names, int desired, Journal journal, Device device) throws Exception {
        int done = 0;
        for (String name : names) {
            int before = device.state(name);
            if (before == desired || (desired == 3 && before >= 2)) continue;
            if (journal.original(name) == null) journal.remember(name, before);
            journal.persist(); // A failed write must never reach the device.
            device.set(name, desired);
            if (device.state(name) != desired) throw new IllegalStateException("State verification failed");
            done++;
        }
        return done;
    }
    static void restore(Journal journal, Device device) throws Exception {
        for (String name : new ArrayList<>(journal.pending())) {
            Integer original = journal.original(name);
            if (original == null || original < 0 || original > 4 || !TvCleanerPolicy.packageId(name))
                throw new IllegalStateException("Invalid recovery state");
            device.set(name, original);
            if (device.state(name) != original) throw new IllegalStateException("Recovery verification failed");
            journal.forget(name);
            journal.persist(); // If interrupted, restoring the same original value again is safe.
        }
    }
}
