package com.leanbitlab.ltvL;

import java.util.Set;

public final class UpdatePermissionPolicyTest {
    private static void expect(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        expect(!UpdatePermissionPolicy.replaced(0, 10)); // No baseline: never infer earlier consent.
        expect(!UpdatePermissionPolicy.replaced(10, 10)); // Resume is not an update.
        expect(UpdatePermissionPolicy.replaced(10, 11));
        expect(UpdatePermissionPolicy.replaced(11, 10)); // Reinstallation/downgrade as well.
        expect(UpdatePermissionPolicy.missing(Set.of(), Set.of(), false).isEmpty());
        expect(UpdatePermissionPolicy.missing(Set.of("usage"), Set.of(), true).equals(Set.of("usage")));
        expect(UpdatePermissionPolicy.missing(Set.of("usage"), Set.of("usage"), true).isEmpty());
        expect(UpdatePermissionPolicy.missing(Set.of("accessibility"), Set.of("accessibility"), false)
            .equals(Set.of("accessibility"))); // Enabled but not bound after update.
        expect(UpdatePermissionPolicy.missing(Set.of("accessibility"), Set.of("accessibility"), true).isEmpty());
        expect(UpdatePermissionPolicy.missing(Set.of("home", "arbitrary"), Set.of(), false).isEmpty());
        expect(UpdatePermissionPolicy.missing(UpdatePermissionPolicy.ACTIONS, Set.of(), false)
            .equals(UpdatePermissionPolicy.ACTIONS));
        expect(UpdatePermissionPolicy.missing(Set.of("notifications", "overlay"), Set.of("overlay"), false)
            .equals(Set.of("notifications")));
        expect(UpdatePermissionPolicy.serviceList("other/.Service:own/.Service", "own/own.Service", false)
            .equals("other/.Service"));
        expect(UpdatePermissionPolicy.serviceList("other/.Service:own/.Service", "own/own.Service", true)
            .equals("other/.Service:own/own.Service"));
        expect(UpdatePermissionPolicy.serviceList("null", "own/own.Service", true).equals("own/own.Service"));
        expect(UpdatePermissionPolicy.serviceList("own/own.Service", "own/own.Service", false).isEmpty());
        expect(UpdatePermissionPolicy.serviceList("other/.Service:other/.Service", "own/own.Service", true)
            .equals("other/.Service:own/own.Service"));
        try {
            UpdatePermissionPolicy.serviceList("other/.Service';exit", "own/own.Service", true);
            throw new AssertionError("Unsafe settings value accepted");
        } catch (IllegalArgumentException expected) { }
        System.out.println("Update permission policy: 18 checks passed");
    }
}
