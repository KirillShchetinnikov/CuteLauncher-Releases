package com.leanbitlab.ltvL;

import android.content.pm.PackageInfo;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(manifest = Config.NONE, sdk = {28, 29, 36})
public class UpdateSignerFallbackTest {
    @Rule public TemporaryFolder temporary = new TemporaryFolder();

    private File apk(String name) throws Exception {
        File file = temporary.newFile();
        try (InputStream input = getClass().getResourceAsStream("/update-signers/" + name + ".apk.bin")) {
            assertNotNull(input);
            Files.copy(input, file.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        }
        return file;
    }

    @Test public void missingSigningInfoReadsVerifiedV2AndV3Signers() throws Exception {
        String[] v2 = UpdateBridge.signerNames(new PackageInfo(), apk("v2-only-with-rsa-pkcs1-sha256-2048"));
        String[] v3 = UpdateBridge.signerNames(new PackageInfo(), apk("v3-only-with-rsa-pkcs1-sha256-2048"));
        assertEquals(1, v2.length);
        assertArrayEquals(v2, v3);
    }

    @Test public void sameSignerAllowsUpdateWhenBothPackageInfosOmitCertificates() throws Exception {
        String[] current = UpdateBridge.signerNames(new PackageInfo(), apk("v2-only-with-rsa-pkcs1-sha256-2048"));
        String[] candidate = UpdateBridge.signerNames(new PackageInfo(), apk("v3-only-with-rsa-pkcs1-sha256-2048"));
        assertNull(UpdatePolicy.rejection("launcher", 183, current, "launcher", 184, candidate));
    }

    @Test public void emptyModernSignerListAlsoFallsBack() throws Exception {
        PackageInfo info = new PackageInfo();
        info.signingInfo = new SigningInfo();
        shadowOf(info.signingInfo).setSignatures(new Signature[0]);
        assertEquals(1, UpdateBridge.signerNames(info, apk("v2-only-with-rsa-pkcs1-sha256-2048")).length);
    }

    @Test public void verifiedCertificatesHaveTheSameEncodingAsModernPackageInfo() throws Exception {
        File file = apk("v2-only-with-rsa-pkcs1-sha256-2048");
        var result = new com.android.apksig.ApkVerifier.Builder(file)
            .setMinCheckedPlatformVersion(29).setMaxCheckedPlatformVersion(29).build().verify();
        assertTrue(result.isVerified());
        PackageInfo info = new PackageInfo();
        info.signingInfo = new SigningInfo();
        shadowOf(info.signingInfo).setSignatures(new Signature[]{
            new Signature(result.getSignerCertificates().get(0).getEncoded())});
        assertArrayEquals(UpdateBridge.signerNames(info), UpdateBridge.signerNames(new PackageInfo(), file));
    }

    @Test public void modernCurrentSignersWinAndLegacyHistoryIsIgnored() throws Exception {
        PackageInfo info = new PackageInfo();
        info.signingInfo = new SigningInfo();
        shadowOf(info.signingInfo).setSignatures(new Signature[]{new Signature("010203")});
        shadowOf(info.signingInfo).setPastSigningCertificates(new Signature[]{new Signature("040506")});
        info.signatures = new Signature[]{new Signature("040506")};
        assertArrayEquals(new String[]{"010203"}, UpdateBridge.signerNames(info, temporary.newFile()));
    }

    @Test public void unsignedAndBrokenSignaturesNeverSupplyTrustedCertificates() throws Exception {
        for (String name : new String[]{"pinsapp-unsigned", "v2-only-with-rsa-pkcs1-sha256-2048-sig-does-not-verify"}) {
            String[] signers = UpdateBridge.signerNames(new PackageInfo(), apk(name));
            assertEquals(name, 0, signers.length);
            assertEquals("invalid_signers", UpdatePolicy.rejection("launcher", 1, new String[]{"a"}, "launcher", 2, signers));
        }
    }

    @Test public void otherSignerIsStillRejected() throws Exception {
        String[] current = UpdateBridge.signerNames(new PackageInfo(), apk("v2-only-with-rsa-pkcs1-sha256-2048"));
        String[] candidate = UpdateBridge.signerNames(new PackageInfo(), apk("v2-only-with-rsa-pkcs1-sha256-4096"));
        assertEquals(1, candidate.length);
        assertEquals("invalid_signature", UpdatePolicy.rejection("launcher", 1, current, "launcher", 2, candidate));
    }

    @Test public void fullMultiSignerSetIsPreserved() throws Exception {
        String[] signers = UpdateBridge.signerNames(new PackageInfo(), apk("two-signers"));
        assertEquals(2, signers.length);
        assertEquals("invalid_signature", UpdatePolicy.rejection("launcher", 1, signers, "launcher", 2, new String[]{signers[0]}));
    }

    @Test public void rotationDoesNotMatchTheOldCertificate() throws Exception {
        File rotated = apk("golden-aligned-v3-lineage-out");
        String[] old = UpdateBridge.signerNames(new PackageInfo(), apk("v2-only-with-rsa-pkcs1-sha256-2048"));
        var verified = new com.android.apksig.ApkVerifier.Builder(rotated)
            .setMinCheckedPlatformVersion(29).setMaxCheckedPlatformVersion(29).build().verify();
        assertTrue(verified.isVerified());
        assertNotNull(verified.getSigningCertificateLineage());
        String[] current = UpdateBridge.signerNames(new PackageInfo(), rotated);
        assertEquals(1, current.length);
        assertEquals("invalid_signature", UpdatePolicy.rejection("launcher", 1, old, "launcher", 2, current));
    }

    @Test public void legacyFieldsDoNotRescueMissingOrUnreadableApk() throws Exception {
        PackageInfo info = new PackageInfo();
        info.signatures = new Signature[]{new Signature("010203")};
        assertEquals(0, UpdateBridge.signerNames(info, new File(temporary.getRoot(), "missing.apk")).length);
        assertEquals(0, UpdateBridge.signerNames(info, temporary.newFile()).length);
    }
}
