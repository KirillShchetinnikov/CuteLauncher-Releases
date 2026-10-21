package com.leanbitlab.ltvL;

import java.util.Arrays;
import java.util.HashSet;

/** Certificate rotation is intentionally not accepted by the local updater. */
final class UpdatePolicy {
    static boolean allows(String installedPackage, long installedVersion, String[] installedSigners,
                          String candidatePackage, long candidateVersion, String[] candidateSigners) {
        return installedPackage != null && installedPackage.equals(candidatePackage)
            && candidateVersion > installedVersion
            && installedSigners != null && candidateSigners != null
            && installedSigners.length > 0 && candidateSigners.length > 0
            && new HashSet<>(Arrays.asList(installedSigners)).equals(new HashSet<>(Arrays.asList(candidateSigners)));
    }
}
