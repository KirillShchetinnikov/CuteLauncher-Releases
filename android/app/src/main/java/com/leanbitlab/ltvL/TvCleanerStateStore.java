package com.leanbitlab.ltvL;

import android.util.AtomicFile;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.json.JSONObject;

/** Private per-firmware states. No API can delete or replace the baseline. Caller holds AdbBridge.LOCK. */
final class TvCleanerStateStore {
    interface Backend {
        byte[] read(String path) throws Exception;
        void write(String path, byte[] bytes) throws Exception;
        void delete(String path) throws Exception;
        Set<String> names(String directory) throws Exception;
    }
    private final Backend files;
    private final String firmware, key;
    TvCleanerStateStore(File root, String firmware, String key) {
        this(new AtomicBackend(root), firmware, key);
    }
    TvCleanerStateStore(Backend files, String firmware, String key) {
        this.files = files; this.firmware = firmware; this.key = key;
    }
    private String baselineFile() { return "tv-cleaner-baseline-" + key + ".json"; }
    private String manualDir() { return "tv-cleaner-manual-" + key; }
    private String manualFile(String id) {
        if (id == null || !id.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"))
            throw new IllegalArgumentException("Invalid state ID");
        return manualDir() + "/" + id + ".json";
    }
    private JSONObject read(String file) throws Exception {
        byte[] bytes = files.read(file);
        if (bytes == null) return null;
        if (bytes.length > 1024 * 1024) throw new IllegalStateException("State too large");
        JSONObject value = new JSONObject(new String(bytes, StandardCharsets.UTF_8));
        if (value.getInt("schemaVersion") != 1 || !firmware.equals(value.getString("fingerprint"))
                || value.getLong("capturedAt") <= 0) throw new IllegalStateException("Invalid state");
        states(value);
        return value;
    }
    static Map<String, Integer> states(JSONObject value) throws Exception {
        JSONObject states = value.getJSONObject("states");
        if (states.length() == 0 || states.length() > 2000) throw new IllegalStateException("Invalid states");
        var result = new LinkedHashMap<String, Integer>();
        for (var keys = states.keys(); keys.hasNext();) {
            String name = keys.next(); Object raw = states.get(name);
            if (!TvCleanerPolicy.packageId(name) || !(raw instanceof Number)
                    || ((Number)raw).doubleValue() != ((Number)raw).intValue()
                    || ((Number)raw).intValue() < 0 || ((Number)raw).intValue() > 4)
                throw new IllegalStateException("Invalid package state");
            result.put(name, ((Number)raw).intValue());
        }
        return result;
    }
    private void write(String file, JSONObject value) throws Exception {
        byte[] bytes = value.toString().getBytes(StandardCharsets.UTF_8);
        if (bytes.length > 1024 * 1024) throw new IllegalStateException("State too large");
        files.write(file, bytes);
        if (!Arrays.equals(bytes, files.read(file))) throw new java.io.IOException("State verification failed");
    }
    JSONObject baseline() throws Exception { return read(baselineFile()); }
    JSONObject ensureBaseline(JSONObject original) throws Exception {
        JSONObject saved = baseline();
        if (saved != null) return saved;
        JSONObject copy = new JSONObject(original.toString());
        copy.remove("changed"); copy.put("reportType", "tvCleanerState"); copy.put("kind", "baseline");
        states(copy);
        write(baselineFile(), copy);
        return baseline();
    }
    List<Map<String, Object>> manualStates() throws Exception {
        var result = new ArrayList<Map<String, Object>>();
        var ids = new LinkedHashSet<String>();
        for (String name : files.names(manualDir())) {
            if (name.endsWith(".json") || name.endsWith(".json.bak"))
                ids.add(name.replaceFirst("\\.json(?:\\.bak)?$", ""));
        }
        if (ids.size() > 100) throw new IllegalStateException("Too many states");
        for (String id : ids) {
            JSONObject value = manual(id);
            result.add(Map.of("id", id, "name", value.getString("name"),
                "capturedAt", value.getLong("capturedAt"), "packageCount", value.getJSONObject("states").length(),
                "description", value.optString("description", ""), "scope", value.optString("scope", "allApplications")));
        }
        result.sort(Comparator.comparingLong(row -> -((Number)row.get("capturedAt")).longValue()));
        return result;
    }
    void saveManual(JSONObject current, String name) throws Exception {
        if (name == null || name.trim().isEmpty() || name.length() > 120
                || name.codePoints().anyMatch(Character::isISOControl)) throw new IllegalArgumentException("Invalid state name");
        if (manualStates().size() >= 100) throw new IllegalStateException("Too many states");
        JSONObject value = new JSONObject(current.toString());
        String id = UUID.randomUUID().toString();
        value.put("id", id).put("name", name.trim()).put("kind", "manual").put("reportType", "tvCleanerState");
        value.remove("changed"); states(value);
        write(manualFile(id), value);
    }
    void saveBeforeList(JSONObject selectedState, String description) throws Exception {
        if (description == null || description.trim().isEmpty() || description.length() > 512
                || description.codePoints().anyMatch(Character::isISOControl)) throw new IllegalArgumentException("Invalid list description");
        String name = description.substring(0, Math.min(description.length(), 120));
        if (Character.isHighSurrogate(name.charAt(name.length()-1))) name = name.substring(0,name.length()-1);
        JSONObject copy = new JSONObject(selectedState.toString()).put("description", description).put("scope", "selectedApplications");
        saveManual(copy, name);
    }
    JSONObject manual(String id) throws Exception {
        JSONObject value = read(manualFile(id));
        if (value == null || !id.equals(value.getString("id")) || !"manual".equals(value.getString("kind")))
            throw new IllegalStateException("State unavailable");
        return value;
    }
    void deleteManual(String id) throws Exception {
        manual(id); // A baseline can never be addressed through this path.
        String file = manualFile(id); files.delete(file);
        if (files.read(file) != null) throw new java.io.IOException("State deletion failed");
    }
    private static final class AtomicBackend implements Backend {
        private final File root;
        AtomicBackend(File root) { this.root = root; }
        private AtomicFile file(String path) { return new AtomicFile(new File(root, path)); }
        public byte[] read(String path) throws Exception {
            AtomicFile file = file(path);
            if (!file.getBaseFile().exists() && !new File(file.getBaseFile() + ".bak").exists()) return null;
            return file.readFully();
        }
        public void write(String path, byte[] bytes) throws Exception {
            AtomicFile file = file(path); FileOutputStream stream = file.startWrite();
            try {
                stream.write(bytes); stream.getFD().sync(); file.finishWrite(stream);
            } catch (Exception error) { file.failWrite(stream); throw error; }
        }
        public void delete(String path) { file(path).delete(); }
        public Set<String> names(String directory) {
            String[] names = new File(root, directory).list();
            return names == null ? Set.of() : new LinkedHashSet<>(Arrays.asList(names));
        }
    }

}
