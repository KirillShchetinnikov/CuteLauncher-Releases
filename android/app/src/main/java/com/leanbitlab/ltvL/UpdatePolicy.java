package com.leanbitlab.ltvL;

import java.util.Arrays;
import java.util.HashSet;

/** Certificate rotation is intentionally not accepted by the local updater. */
final class UpdatePolicy {
    static boolean allows(String installedPackage, long installedVersion, String[] installedSigners,
                          String candidatePackage, long candidateVersion, String[] candidateSigners) {
        return rejection(installedPackage, installedVersion, installedSigners,
            candidatePackage, candidateVersion, candidateSigners) == null;
    }

    /** Stable reason codes only; never returns certificates or private paths. */
    static String rejection(String installedPackage, long installedVersion, String[] installedSigners,
                            String candidatePackage, long candidateVersion, String[] candidateSigners) {
        if (installedPackage == null || !installedPackage.equals(candidatePackage)) return "invalid_package";
        if (candidateVersion <= installedVersion) return "invalid_version";
        if (installedSigners == null || candidateSigners == null
            || installedSigners.length == 0 || candidateSigners.length == 0) return "invalid_signers";
        if (!new HashSet<>(Arrays.asList(installedSigners)).equals(new HashSet<>(Arrays.asList(candidateSigners))))
            return "invalid_signature";
        return null;
    }
}
