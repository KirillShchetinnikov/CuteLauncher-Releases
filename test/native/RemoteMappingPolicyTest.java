package com.leanbitlab.ltvL;

import java.util.*;

public class RemoteMappingPolicyTest {
    static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
    static Map<String, Object> row(int key, String action, String target) {
        return Map.of("keyCode", key, "enabled", true, "action", action, "target", target);
    }
    static void invalid(Map<String, Object> value) {
        try { RemoteMappingConfiguration.fromMap(value); throw new AssertionError("Invalid config accepted"); }
        catch (IllegalArgumentException expected) { }
    }
    public static void main(String[] args) {
        for (int key : new int[]{0,3,4,19,20,21,22,23,24,25,26,66,96,97,109,111,
                160,177,179,181,219,223,224,231,276,65536})
            require(!RemoteMappingConfiguration.assignable(key), "Protect key " + key);
        for (int key : new int[]{164,288,83,4001,178,167,166,4514,4056,165,4062,4099,4140,4159,190,4020,4137})
            require(RemoteMappingConfiguration.assignable(key), "Allow confirmed key " + key);
        for (String url : new String[]{"https://example.org/api/webhook/secret", "http://192.168.1.2:8123/api/webhook/secret",
            "http://homeassistant.local:8123/api/webhook/secret", "http://127.0.0.1/hook", "http://172.31.1.2/hook"})
            require(RemoteMappingConfiguration.webhook(url), "Allow valid webhook");
        for (String url : new String[]{"http://example.org/hook", "http://172.32.1.2/hook", "file:///tmp/hook", "https://user:pass@example.org/hook",
            "https://example.org/hook#secret", "https://example.org:0/hook", "http://192.168.1.999/hook", "https://example.org/\nsecret"})
            require(!RemoteMappingConfiguration.webhook(url), "Reject invalid webhook");
        Map<String, Object> saved = Map.of("enabled", true, "bindings", List.of(row(4137,"home",""),row(190,"app","tv.example.player")));
        RemoteMappingConfiguration config = RemoteMappingConfiguration.fromMap(saved);
        require(config.binding(4137) != null, "TCL Home mapping survives round trip");
        require(RemoteMappingConfiguration.fromMap(config.toMap()).binding(190).target().equals("tv.example.player"), "App target survives round trip");
        invalid(Map.of("enabled",true,"bindings",List.of(row(3,"home",""))));
        invalid(Map.of("enabled",true,"bindings",List.of(row(190,"home",""),row(190,"back",""))));
        var panel = RemoteMappingConfiguration.fromMap(Map.of("enabled",true,"bindings",List.of(row(190,"panel",""))));
        require(RemoteMappingConfiguration.fromMap(panel.toMap()).binding(190).action().equals("panel"), "Panel action survives round trip");
        invalid(Map.of("enabled",true,"bindings",List.of(row(190,"panel","unexpected"))));
        invalid(Map.of("enabled",true,"bindings",List.of(row(190,"unknown",""))));
        invalid(Map.of("enabled",true,"bindings",List.of(row(190,"app",""))));
        invalid(Map.of("enabled",true,"bindings",List.of(row(190,"webhook","http://example.org/secret"))));
        invalid(Map.of("enabled",true,"bindings",Collections.nCopies(33,row(190,"home",""))));
        require(RemoteMappingConfiguration.empty().binding(190) == null, "Off by default");
        var home = config.binding(4137);
        RemoteMappingPolicy policy = new RemoteMappingPolicy();
        require(policy.event(5,4137,0,0,100,false,home).consume(), "Consume down");
        require(policy.event(5,4137,0,1,100,false,home).fire() == null, "Never repeat held action");
        require(policy.event(5,4137,1,0,100,false,home).fire().equals(home), "Fire once on release");
        require(!policy.event(5,4137,1,0,100,false,home).consume(), "No orphan release action");
        policy.event(5,4137,0,0,200,false,home);
        var cancelled = policy.event(5,4137,1,0,200,true,home);
        require(cancelled.consume() && cancelled.fire() == null, "Consume cancelled release without action");
        policy.event(5,4137,0,0,300,false,home);
        var disabled = policy.event(5,4137,1,0,300,false,null);
        require(disabled.consume() && disabled.fire() == null, "Switch off mid-press preserves event pair");
        policy.event(5,4137,0,0,400,false,home); policy.cancelActions();
        var interrupted = policy.event(5,4137,1,0,400,false,home);
        require(interrupted.consume() && interrupted.fire() == null, "Interrupt cancels action and preserves release");
        policy.event(5,4137,0,0,500,false,home);
        require(!policy.event(6,4137,1,0,500,false,home).consume(), "Do not mix devices");
        require(policy.event(5,4137,1,0,500,false,home).fire() != null, "Original device still works");
        System.out.println("RemoteMappingPolicy: all checks passed");
    }
}
