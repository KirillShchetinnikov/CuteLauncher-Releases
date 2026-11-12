package com.leanbitlab.ltvL;

import org.junit.Test;
import java.util.ArrayList;
import java.util.List;
import static org.junit.Assert.*;

public class RecentAppsMemoryTest {
    private static String block(int pid, String total) {
        return "** MEMINFO in pid " + pid + " [custom.process] **\n App Summary\n " + total + "\n";
    }
    @Test public void sumsProcessesWithoutDoubleCountingSummaryAndFiltersOtherUsers() {
        String dump = block(12, "TOTAL PSS: 100 TOTAL RSS: 500 TOTAL SWAP PSS: 40")
            + block(13, "TOTAL: 25 TOTAL SWAP PSS: 0") + block(14, "TOTAL PSS: 900")
            + "Total PSS by process:\n 125 kB: something\n";
        assertEquals(Long.valueOf(125 * 1024), RecentAppsMemory.parse(dump,
            "PID UID\n12 10123\n13 99001\n14 1010123\n"));
    }
    @Test public void absentTruncatedTimedOutMalformedAndOverflowAreUnknown() {
        String users = "12 10123\n13 10123\n";
        for (String dump : List.of("", "No process found for: tv.app", "Permission Denial",
                block(12, "TOTAL PSS: 10") + block(13, "Java Heap: 10"),
                block(12, "TOTAL PSS: 10") + "*** SERVICE DUMP TIMEOUT EXPIRED ***",
                block(12, "TOTAL PSS: -1"), block(12, "TOTAL PSS: 999999999999999999999"),
                block(12, "TOTAL PSS: 9223372036854775807"),
                block(12, "TOTAL PSS: 10") + block(12, "TOTAL PSS: 10"))) {
            assertNull(dump, RecentAppsMemory.parse(dump, users));
        }
        assertNull(RecentAppsMemory.parse(block(12, "TOTAL PSS: 10"), "PID UID\n"));
        assertEquals(Long.valueOf(0), RecentAppsMemory.parse(block(12, "TOTAL PSS: 0"), users));
    }
    @Test public void readUsesPackageModeBoundedDumpAndStopsOnCancellation() throws Exception {
        List<String> commands = new ArrayList<>();
        AdbBridge.Shell shell = new AdbBridge.Shell() {
            public String execute(String command) {
                commands.add(command);
                if (command.equals("id -u")) return "2000";
                if (command.equals("am get-current-user")) return "0";
                if (command.equals("ps -A -n -o PID,UID")) return "12 10123\n";
                assertEquals("dumpsys -t 1 meminfo --local -s --package tv.app", command);
                return block(12, "TOTAL PSS: 42");
            }
            public void close() {}
        };
        assertEquals(java.util.Map.of("status", "running", "pssBytes", 42L * 1024),
            RecentAppsMemory.read(shell, "tv.app", () -> false));
        commands.clear();
        assertEquals(RecentAppsMemory.UNAVAILABLE, RecentAppsMemory.read(shell, "tv.app", () -> commands.size() >= 3));
        assertEquals(3, commands.size());
        commands.clear();
        assertEquals(RecentAppsMemory.UNAVAILABLE, RecentAppsMemory.read(shell, "tv.app", () -> true));
        assertTrue(commands.isEmpty());
        try { RecentAppsMemory.read(shell, "tv.app;reboot", () -> false); fail(); }
        catch (IllegalArgumentException expected) { }
        assertTrue(commands.isEmpty());
    }
    @Test public void onlyExactNoProcessResponseMeansUnloaded() {
        assertEquals(java.util.Map.of("status", "unloaded"),
            RecentAppsMemory.snapshot("No process found for: tv.app\r\n", "PID UID\n", "tv.app"));
        for (String dump : List.of("", "Permission Denial", "No process found for: tv.other",
                "No process found for: tv.app\n*** SERVICE DUMP TIMEOUT EXPIRED ***",
                "warning\nNo process found for: tv.app", block(12, "Java Heap: 10"))) {
            assertEquals(dump, RecentAppsMemory.UNAVAILABLE,
                RecentAppsMemory.snapshot(dump, "12 10123\n", "tv.app"));
        }
    }
    @Test public void tclAu01SummaryIsRunningAndCanTransitionBackFromUnloaded() {
        String dump = "Applications Memory Usage (in Kilobytes):\r\n"
            + "Uptime: 92404922 Realtime: 92404922\r\n\r\n"
            + "** MEMINFO in pid 2216 [com.alphainventor.filemanager] **\r\n \r\n"
            + " App Summary\r\n                       Pss(KB)                        Rss(KB)\r\n"
            + "                        ------                         ------\r\n"
            + "           TOTAL PSS:    10599            TOTAL RSS:    44664       TOTAL SWAP PSS:     1060\r\n";
        assertEquals(java.util.Map.of("status", "running", "pssBytes", 10599L * 1024),
            RecentAppsMemory.snapshot(dump, " PID   UID\r\n2216 10123\r\n", "com.alphainventor.filemanager"));
        assertEquals(RecentAppsMemory.UNAVAILABLE,
            RecentAppsMemory.snapshot(dump, " PID   UID\r\n", "com.alphainventor.filemanager"));
    }
}
