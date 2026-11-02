package com.leanbitlab.ltvL;
import java.util.*;

/** Per-package audit around the existing write-ahead recovery; stops at the first uncertain result. */
final class TvCleanerOperation {
    record Result(List<Map<String, Object>> rows, boolean failed, int skipped) {}
    static Result apply(List<String> names, int desired, TvCleanerRecovery.Journal journal,
                        TvCleanerRecovery.Device device) throws Exception {
        var states = new LinkedHashMap<String, Integer>();
        for (String name : names) states.put(name, desired);
        return run(states, null, null, journal, device);
    }
    static Result restore(Map<String, Integer> states, Set<String> installed, Set<String> protectedNames,
                          TvCleanerRecovery.Journal journal, TvCleanerRecovery.Device device) throws Exception {
        return run(states, installed, protectedNames, journal, device);
    }
    private static Result run(Map<String, Integer> states, Set<String> installed, Set<String> protectedNames,
                              TvCleanerRecovery.Journal journal, TvCleanerRecovery.Device device) throws Exception {
        for (var entry : states.entrySet()) {
            if (!TvCleanerPolicy.packageId(entry.getKey()) || entry.getValue() == null ||
                    entry.getValue() < 0 || entry.getValue() > 4) throw new IllegalArgumentException("Invalid operation");
        }
        var rows = new ArrayList<Map<String, Object>>(); boolean failed = false; int skipped = 0;
        for (var entry : states.entrySet()) {
            String name = entry.getKey(); int desired = entry.getValue();
            var row = new LinkedHashMap<String, Object>();
            row.put("package", name); row.put("desiredState", desired);
            if (failed) { row.put("status", "notAttempted"); rows.add(row); continue; }
            if (installed != null && !installed.contains(name)) {
                row.put("status", "skippedMissing"); skipped++; rows.add(row); continue;
            }
            var probe = new Probe(journal, device);
            try {
                int count = installed == null ? TvCleanerRecovery.apply(List.of(name), desired, probe, probe)
                    : TvCleanerRecovery.restoreStates(Map.of(name, desired), installed, protectedNames, probe, probe);
                if (installed != null && count > 0) { row.put("status", "skippedProtected"); skipped += count; }
                else row.put("status", probe.command ? "changed" : "unchanged");
            } catch (Exception error) {
                failed = true; row.put("status", "failed"); row.put("reason", probe.stage);
                // A command may have reached the device before transport failed. Never infer its state.
                try { probe.after = device.state(name); } catch (Exception unavailable) { probe.after = null; }
            }
            if (probe.before != null) row.put("beforeState", probe.before);
            if (probe.after != null) row.put("afterState", probe.after);
            rows.add(row);
        }
        return new Result(rows, failed, skipped);
    }
    private static final class Probe implements TvCleanerRecovery.Journal, TvCleanerRecovery.Device {
        final TvCleanerRecovery.Journal journal; final TvCleanerRecovery.Device device;
        String stage = "read"; Integer before, after; boolean command;
        Probe(TvCleanerRecovery.Journal journal, TvCleanerRecovery.Device device) { this.journal = journal; this.device = device; }
        public int state(String name) throws Exception {
            stage = command ? "verify" : "read";
            int value = device.state(name);
            if (before == null) before = value;
            after = value; return value;
        }
        public void set(String name, int value) throws Exception { stage = "command"; command = true; device.set(name, value); }
        public Integer original(String name) throws Exception { stage = "journal"; return journal.original(name); }
        public void remember(String name, int value) throws Exception { stage = "journal"; journal.remember(name, value); }
        public Set<String> pending() throws Exception { return journal.pending(); }
        public void forget(String name) throws Exception { stage = "journal"; journal.forget(name); }
        public void persist() throws Exception { stage = "journal"; journal.persist(); }
    }
}
