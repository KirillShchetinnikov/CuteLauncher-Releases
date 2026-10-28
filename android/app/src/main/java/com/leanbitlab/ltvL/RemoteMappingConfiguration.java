package com.leanbitlab.ltvL;

import java.net.URI;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Device-local mappings. Essential navigation is protected; Home allows hold only. */
final class RemoteMappingConfiguration {
    record Binding(int keyCode, boolean enabled, String action, String target, String trigger, String name) {
        Binding(int keyCode, boolean enabled, String action, String target, String trigger) { this(keyCode, enabled, action, target, trigger, ""); }
        Binding(int keyCode, boolean enabled, String action, String target) { this(keyCode, enabled, action, target, "press"); }
        String slot() { return keyCode + ":" + trigger; }
        Map<String, Object> toMap() {
            return Map.of("keyCode", keyCode, "enabled", enabled, "action", action, "target", target, "trigger", trigger, "name", name);
        }
    }
    static final Set<String> ACTIONS = Set.of("app", "home", "back", "webhook", "panel", "recents");
    static boolean assignable(int code, String trigger) { return assignable(code) || code == 3 && "hold".equals(trigger); }
    final boolean enabled;
    final Map<String, Binding> bindings;
    RemoteMappingConfiguration(boolean enabled, Map<String, Binding> bindings) {
        this.enabled = enabled;
        this.bindings = Map.copyOf(bindings);
    }
    static RemoteMappingConfiguration empty() { return new RemoteMappingConfiguration(false, Map.of()); }
    static boolean assignable(int code) {
        return code > 0 && code <= 65535 && !Set.of(3, 4, 19, 20, 21, 22, 23, 24, 25, 26,
            66, 84, 96, 97, 109, 111, 160, 177, 179, 181, 219, 223, 224, 231,
            276, 280, 281, 282, 283).contains(code);
    }
    static boolean webhook(String value) {
        try {
            if (value.length() > 4096 || value.chars().anyMatch(c -> c < 32 || c == 127)) return false;
            URI uri = new URI(value);
            if (uri.getHost() == null || uri.getRawUserInfo() != null || uri.getRawFragment() != null
                    || uri.getPort() == 0 || uri.getPort() > 65535 || uri.getRawPath().isEmpty()) return false;
            if ("https".equalsIgnoreCase(uri.getScheme())) return true;
            if (!"http".equalsIgnoreCase(uri.getScheme())) return false;
            String host = uri.getHost().toLowerCase(java.util.Locale.ROOT);
            if (host.equals("localhost") || host.endsWith(".local") || host.endsWith(".lan")) return true;
            if (!host.matches("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+")) return false;
            String[] parts = host.split("\\.");
            int a = Integer.parseInt(parts[0]), b = Integer.parseInt(parts[1]);
            for (String part : parts) if (Integer.parseInt(part) > 255) return false;
            return a == 10 || a == 127 || a == 192 && b == 168 || a == 172 && b >= 16 && b <= 31;
        } catch (Exception ignored) { return false; }
    }
    static RemoteMappingConfiguration fromMap(Map<?, ?> source) {
        if (!(source.get("enabled") instanceof Boolean enabled)
                || !(source.get("bindings") instanceof List<?> entries) || entries.size() > 64)
            throw new IllegalArgumentException();
        Map<String, Binding> bindings = new LinkedHashMap<>();
        for (Object entry : entries) {
            if (!(entry instanceof Map<?, ?> row) || !(row.get("keyCode") instanceof Number number)
                    || !(row.get("enabled") instanceof Boolean active)
                    || !(row.get("action") instanceof String action)
                    || !(row.get("target") instanceof String target)) throw new IllegalArgumentException();
            int code = number.intValue();
            if (row.containsKey("trigger") && !(row.get("trigger") instanceof String)) throw new IllegalArgumentException();
            String trigger = row.containsKey("trigger") ? (String)row.get("trigger") : "press";
            String slot = code + ":" + trigger;
            if (number.doubleValue() != code || !assignable(code, trigger) || !ACTIONS.contains(action)
                    || !Set.of("press", "hold").contains(trigger) || bindings.containsKey(slot)) throw new IllegalArgumentException();
            if (action.equals("app") && !target.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+")
                    || action.equals("webhook") && !webhook(target)
                    || (action.equals("home") || action.equals("back") || action.equals("panel") || action.equals("recents")) && !target.isEmpty())
                throw new IllegalArgumentException();
            String name = row.containsKey("name") && row.get("name") instanceof String text ? text : "";
            if (name.length() > 80) throw new IllegalArgumentException();
            bindings.put(slot, new Binding(code, active, action, target, trigger, name));
        }
        return new RemoteMappingConfiguration(enabled, bindings);
    }
    Binding binding(int code) {
        return binding(code, "press");
    }
    Binding pressBinding(int code) {
        return code == 3 && binding(code, "hold") != null ? new Binding(code, true, "home", "") : binding(code);
    }
    Binding binding(int code, String trigger) {
        Binding binding = bindings.get(code + ":" + trigger);
        return enabled && binding != null && binding.enabled() ? binding : null;
    }
    Map<String, Object> toMap() {
        List<Map<String, Object>> rows = new ArrayList<>();
        bindings.values().stream().sorted(java.util.Comparator.comparingInt(Binding::keyCode).thenComparing(Binding::trigger))
            .forEach(binding -> rows.add(binding.toMap()));
        return Map.of("enabled", enabled, "bindings", rows);
    }
}
