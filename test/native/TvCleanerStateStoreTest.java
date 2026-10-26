package com.leanbitlab.ltvL;

import java.util.*;
import org.json.JSONObject;

/** Real JSON/storage policy with an injected backend; Android AtomicFile is compiled separately. */
public final class TvCleanerStateStoreTest {
    static final class Memory implements TvCleanerStateStore.Backend {
        final Map<String, byte[]> files = new LinkedHashMap<>();
        boolean failWrite;
        public byte[] read(String path) { return files.get(path); }
        public void write(String path, byte[] value) throws Exception {
            if (failWrite) throw new Exception("disk full");
            files.put(path, value.clone());
        }
        public void delete(String path) { files.remove(path); }
        public Set<String> names(String dir) {
            var names = new LinkedHashSet<String>();
            for (String name : files.keySet()) if (name.startsWith(dir + "/")) names.add(name.substring(dir.length() + 1));
            return names;
        }
    }
    interface Action { void run() throws Exception; }
    static void fails(Action action) throws Exception {
        try { action.run(); } catch (Exception expected) { return; }
        throw new AssertionError("Expected failure");
    }
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static JSONObject state(int mode, long date) throws Exception {
        return new JSONObject().put("schemaVersion", 1).put("fingerprint", "firmware")
            .put("capturedAt", date).put("states", new JSONObject().put("org.example.app", mode))
            .put("changed", new JSONObject());
    }
    public static void main(String[] args) throws Exception {
        Memory disk = new Memory();
        var store = new TvCleanerStateStore(disk, "firmware", "key");
        check(store.baseline() == null);
        store.ensureBaseline(state(0, 1000));
        byte[] original = disk.files.get("tv-cleaner-baseline-key.json").clone();
        store.ensureBaseline(state(3, 2000));
        check(Arrays.equals(original, disk.files.get("tv-cleaner-baseline-key.json")));
        check(store.baseline().getLong("capturedAt") == 1000);
        check(store.baseline().getJSONObject("states").getInt("org.example.app") == 0);
        store.saveManual(state(3, 2000), "Before changes");
        store.saveManual(state(1, 3000), "2026-10-25 16:30:00");
        var copies = store.manualStates(); check(copies.size() == 2);
        String newest = (String)copies.get(0).get("id");
        check(copies.get(0).get("name").equals("2026-10-25 16:30:00"));
        check(store.manual(newest).getJSONObject("states").getInt("org.example.app") == 1);
        check(store.manual(newest).getString("fingerprint").equals("firmware"));
        store.deleteManual(newest); check(store.manualStates().size() == 1);
        for (String bad : List.of("baseline", "../tv-cleaner-baseline-key", "", "/tmp/a", "key.json")) {
            fails(() -> store.deleteManual(bad)); fails(() -> store.manual(bad));
        }
        check(Arrays.equals(original, disk.files.get("tv-cleaner-baseline-key.json")));
        for (String bad : List.of("", "  ", "name\ncommand", "x".repeat(121))) fails(() -> store.saveManual(state(0, 4000), bad));
        check(store.manualStates().size() == 1);
        fails(() -> new TvCleanerStateStore(disk, "another-firmware", "key").baseline());
        Memory full = new Memory(); full.failWrite = true;
        fails(() -> new TvCleanerStateStore(full, "firmware", "key").ensureBaseline(state(0, 1)));
        check(full.files.isEmpty());
        // Existing but corrupt baseline is never replaced with today's state.
        disk.files.put("tv-cleaner-baseline-key.json", "broken".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        fails(() -> store.ensureBaseline(state(3, 5000)));
        check(new String(disk.files.get("tv-cleaner-baseline-key.json"), java.nio.charset.StandardCharsets.UTF_8).equals("broken"));
        for (Object invalid : List.of(5, -1, 1.5, "1")) {
            JSONObject bad = state(0, 1000); bad.getJSONObject("states").put("org.example.app", invalid);
            fails(() -> TvCleanerStateStore.states(bad));
        }
        Memory subsetDisk = new Memory();
        var subsetStore = new TvCleanerStateStore(subsetDisk, "firmware", "key");
        JSONObject baseline = state(0, 1000);
        baseline.getJSONObject("states").put("org.example.unrelated", 1);
        subsetStore.ensureBaseline(baseline);
        byte[] baseBytes = subsetDisk.files.get("tv-cleaner-baseline-key.json").clone();
        subsetStore.saveBeforeList(state(0,2000), "Before applying list: owner TV");
        var row = subsetStore.manualStates().get(0);
        JSONObject subset = subsetStore.manual(row.get("id").toString());
        check(subset.getJSONObject("states").length() == 1);
        check(!subset.getJSONObject("states").has("org.example.unrelated"));
        check(row.get("scope").equals("selectedApplications"));
        check(row.get("description").equals("Before applying list: owner TV"));
        check(Arrays.equals(baseBytes,subsetDisk.files.get("tv-cleaner-baseline-key.json")));
        subsetDisk.failWrite = true;
        fails(() -> subsetStore.saveBeforeList(state(0,3000), "Before applying list: failed"));
        check(subsetStore.manualStates().size()==1);
        System.out.println("TvCleanerStateStoreTest passed");
    }
}
