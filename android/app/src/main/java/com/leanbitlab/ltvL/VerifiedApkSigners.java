package com.leanbitlab.ltvL;

import com.android.apksig.ApkVerifier;
import java.io.File;
import java.util.List;
import java.security.cert.X509Certificate;

/** Reads current signers only after verifying the complete APK for this Android API. */
final class VerifiedApkSigners {
    private VerifiedApkSigners() {}

    static String[] read(File apk, int api) throws Exception {
        if (apk == null || !apk.isFile() || apk.length() == 0) return new String[0];
        ApkVerifier.Result result = new ApkVerifier.Builder(apk)
            .setMinCheckedPlatformVersion(api)
            .setMaxCheckedPlatformVersion(api)
            .build().verify();
        if (!result.isVerified()) return new String[0];
        List<X509Certificate> certificates = result.getSignerCertificates();
        String[] names = new String[certificates.size()];
        for (int i = 0; i < certificates.size(); i++) {
            // Same DER hex representation as Android Signature.toCharsString().
            byte[] encoded = certificates.get(i).getEncoded();
            StringBuilder name = new StringBuilder(encoded.length * 2);
            for (byte value : encoded) {
                name.append(Character.forDigit((value & 255) >>> 4, 16));
                name.append(Character.forDigit(value & 15, 16));
            }
            names[i] = name.toString();
        }
        return names;
    }
}
