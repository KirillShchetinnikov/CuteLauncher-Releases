package com.leanbitlab.ltvL;

import org.junit.Test;
import static org.junit.Assert.*;

public class UpdatePolicyReasonsTest {
    private final String[] signing = {"certificate-a", "certificate-b"};

    @Test public void rejectsWrongPackageBeforeComparingVersionOrCertificates() {
        assertEquals("invalid_package", UpdatePolicy.rejection("launcher", 2, signing, "other", 1, null));
    }

    @Test public void rejectsSameAndOlderBuilds() {
        for (long version : new long[]{1, 2})
            assertEquals("invalid_version", UpdatePolicy.rejection("launcher", 2, signing, "launcher", version, signing));
    }

    @Test public void distinguishesMissingCertificatesFromDifferentCertificates() {
        for (String[] missing : new String[][]{null, new String[0]}) {
            assertEquals("invalid_signers", UpdatePolicy.rejection("launcher", 2, missing, "launcher", 3, signing));
            assertEquals("invalid_signers", UpdatePolicy.rejection("launcher", 2, signing, "launcher", 3, missing));
        }
        assertEquals("invalid_signature", UpdatePolicy.rejection("launcher", 2, signing, "launcher", 3, new String[]{"other"}));
        assertEquals("invalid_signature", UpdatePolicy.rejection("launcher", 2, signing, "launcher", 3, new String[]{"certificate-a"}));
    }

    @Test public void acceptsNewerBuildWithSameSignerSetInAnyOrder() {
        assertNull(UpdatePolicy.rejection("launcher", 2, signing, "launcher", 3, new String[]{"certificate-b", "certificate-a"}));
        assertTrue(UpdatePolicy.allows("launcher", 2, signing, "launcher", 3, signing));
    }
}
