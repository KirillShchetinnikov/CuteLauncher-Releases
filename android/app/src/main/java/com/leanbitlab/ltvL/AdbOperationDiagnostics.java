package com.leanbitlab.ltvL;

import java.util.LinkedHashMap;
import java.util.Map;

/** Request-local metadata only. Never stores shell text, output, addresses or package names. */
final class AdbOperationDiagnostics {
    private static final ThreadLocal<Map<String, Object>> CURRENT = new ThreadLocal<>();

    static void begin() { CURRENT.set(new LinkedHashMap<>()); stage("connect"); }
    static Map<String, Object> finish() {
        var value = CURRENT.get();
        CURRENT.remove();
        return value == null ? Map.of() : new LinkedHashMap<>(value);
    }
    static void stage(String stage) { put("stage", stage); }
    static void wifi(AdbWifiSafety.Inspection inspection) {
        var value = CURRENT.get();
        if (value != null) value.putAll(inspection.diagnostic());
    }
    static void command(String command) {
        put("command", commandKind(command));
        var value = CURRENT.get();
        if (value != null) {
            value.remove("exitCode");
            @SuppressWarnings("unchecked")
            var commands = (java.util.List<Map<String, Object>>) value.computeIfAbsent("shell", key -> new java.util.ArrayList<>());
            if (commands.size() == 8) commands.remove(0);
            var item = new LinkedHashMap<String, Object>();
            item.put("command", DiagnosticRedactor.redact(command));
            commands.add(item);
        }
    }
    @SuppressWarnings("unchecked")
    private static Map<String, Object> lastCommand() {
        var value = CURRENT.get();
        if (value == null || !(value.get("shell") instanceof java.util.List<?>)) return null;
        var commands = (java.util.List<Map<String, Object>>)value.get("shell");
        return commands.isEmpty() ? null : commands.get(commands.size() - 1);
    }
    static void exit(int code) {
        put("exitCode", code);
        var command = lastCommand();
        if (command != null) command.put("exitCode", code);
    }
    static void output(String output, String error) {
        var command = lastCommand();
        if (command != null) {
            command.put("stdout", DiagnosticRedactor.redact(output));
            command.put("stderr", DiagnosticRedactor.redact(error));
        }
    }
    static void failure(Throwable failure) {
        put("exception", exceptionKind(failure));
        put("exceptionText", DiagnosticRedactor.redact(failure.toString()));
    }
    private static void put(String key, Object value) {
        var current = CURRENT.get();
        if (current != null) current.put(key, value);
    }
    static String exceptionKind(Throwable failure) {
        if (failure instanceof java.net.SocketTimeoutException || failure instanceof java.util.concurrent.TimeoutException) return "timeout";
        if (failure instanceof java.net.ConnectException || failure instanceof java.net.SocketException) return "connection";
        if (failure instanceof java.io.IOException) return "io";
        if (failure instanceof SecurityException) return "security";
        if (failure instanceof IllegalArgumentException) return "argument";
        if (failure instanceof IllegalStateException) return "state";
        if (failure instanceof LinkageError) return "linkage";
        return "other";
    }
    static String commandKind(String command) {
        if (AdbWifiSafety.COMMAND.equals(command)) return "wifi_configurations";
        if (command.equals("am get-current-user")) return "current_user";
        if (command.equals("id -u")) return "shell_identity";
        if (command.startsWith("cmd package resolve-activity")) return "resolve_home";
        if (command.startsWith("cmd package query-activities")) return "query_home";
        if (command.startsWith("cmd package set-home-activity")) return "set_home";
        if (command.startsWith("pm ")) return "package_state";
        if (command.startsWith("settings ")) return "settings";
        if (command.startsWith("appops ") || command.startsWith("cmd appops ")) return "appops";
        if (command.startsWith("cmd notification ")) return "notification";
        if (command.startsWith("ps ") || command.startsWith("am force-stop ")) return "process";
        return "other";
    }
}
