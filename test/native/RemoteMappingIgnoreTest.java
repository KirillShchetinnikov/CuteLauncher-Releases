package com.leanbitlab.ltvL;
import java.util.*;

public final class RemoteMappingIgnoreTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static Map<String, Object> row(int code, String target) {
        return Map.of("keyCode", code, "enabled", true, "action", "ignore", "target", target);
    }
    public static void main(String[] args) {
        var config = RemoteMappingConfiguration.fromMap(Map.of("enabled", true,
                "bindings", List.of(row(4137, ""))));
        var saved = RemoteMappingConfiguration.fromMap(config.toMap());
        check(saved.binding(4137).action().equals("ignore"));
        var policy = new RemoteMappingPolicy();
        var binding = saved.binding(4137);
        check(policy.event(1, 4137, 0, 0, 100, false, binding).consume());
        check(policy.event(1, 4137, 0, 1, 100, false, binding).fire() == null);
        var up = policy.event(1, 4137, 1, 0, 100, false, binding);
        check(up.consume() && up.fire().action().equals("ignore"));
        check(!policy.event(1, 4138, 0, 0, 100, false, null).consume());
        for (int code : List.of(3, 4, 19, 20, 21, 22, 23, 24, 25, 26)) {
            try { RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(row(code, ""))));
                throw new AssertionError("Protected short key accepted"); }
            catch (IllegalArgumentException expected) { }
        }
        try { RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(row(4137, "org.example"))));
            throw new AssertionError("Ignore accepted a target"); }
        catch (IllegalArgumentException expected) { }
        System.out.println("RemoteMappingIgnoreTest passed");
    }
}
