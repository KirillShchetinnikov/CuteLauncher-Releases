package com.leanbitlab.ltvL;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Pattern;

public final class ReportExportPolicyTest {
    public static void main(String[] args) throws Exception {
        // Use the name produced by Dart so renaming the unified report breaks this contract test.
        String dart = Files.readString(Path.of("lib/diagnostics_report.dart"));
        var producer = Pattern.compile("'(cutelauncher_[a-z]+_)\\$\\{DateTime\\.now\\(\\)\\.millisecondsSinceEpoch\\}\\.json'").matcher(dart);
        if (!producer.find()) throw new AssertionError("Unified report filename producer not found");
        require(producer.group(1) + "1793000000000.json", true);
        // Check every export kind accepted by the cleaner client, including manual states.
        String cleaner = Files.readString(Path.of("lib/tv_cleaner.dart"));
        var kinds = Pattern.compile("\\[([^\\]]+)\\]\\.contains\\(kind\\)").matcher(cleaner);
        if (!kinds.find()) throw new AssertionError("Cleaner export kinds not found");
        var kind = Pattern.compile("'([a-z]+)'").matcher(kinds.group(1));
        int count = 0;
        while (kind.find()) {
            require("cutelauncher_" + kind.group(1) + "_1793000000000.json", true);
            count++;
        }
        if (count == 0) throw new AssertionError("No cleaner export kinds checked");
        for (String type : new String[]{"errors", "compatibility", "apps", "disabled", "restore"})
            require("cutelauncher_" + type + "_1793000000000.json", true);
        for (String name : new String[]{null, "", "../cutelauncher_diagnostics_1.json",
                "cutelauncher_diagnostics_1/../../other.json", "cutelauncher_backup_1.json",
                "cutelauncher_diagnostics_.json", "cutelauncher_diagnostics_-1.json",
                "cutelauncher_diagnostics_1Xjson", "cutelauncher_diagnostics_1.json\n"})
            require(name, false);
        System.out.println("ReportExportPolicy: diagnostics and cleaner producer contracts, legacy and unsafe names passed");
    }

    private static void require(String name, boolean expected) {
        if (ReportExportPolicy.validName(name) != expected)
            throw new AssertionError("Unexpected report filename validation: " + name);
    }
}
