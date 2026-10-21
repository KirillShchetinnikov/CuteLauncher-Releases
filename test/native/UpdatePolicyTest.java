package com.leanbitlab.ltvL;

public class UpdatePolicyTest {
    static void expect(boolean value, boolean expected) {
        if (value != expected) throw new AssertionError("Unexpected upgrade decision");
    }
    public static void main(String[] arguments) {
        String[] signing = {"certificate-a", "certificate-b"};
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 3, new String[]{"certificate-b", "certificate-a"}), true);
        expect(UpdatePolicy.allows("launcher", 2, signing, "other", 3, signing), false);
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 2, signing), false);
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 1, signing), false);
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 3, new String[]{"certificate-a"}), false);
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 3, new String[]{"untrusted"}), false);
        expect(UpdatePolicy.allows("launcher", 2, signing, "launcher", 3, new String[0]), false);
        expect(UpdatePolicy.allows("launcher", 2, null, "launcher", 3, signing), false);
        System.out.println("Update policy: 8 checks passed");
    }
}
