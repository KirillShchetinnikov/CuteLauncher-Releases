package com.leanbitlab.ltvL;

/** Export names are also cache filenames; accept only known reports without paths. */
final class ReportExportPolicy {
    static boolean validName(String name) {
        return name != null
            && name.matches("cutelauncher_(diagnostics|errors|compatibility|apps|disabled|restore|state)_[0-9]+\\.json");
    }
}
