package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import static org.junit.Assert.*;

public class VpnStartupRecoveryTest {
    static final String APP = "org.amnezia.awg";
    static final class Shell implements VpnStartupRecovery.Shell {
        String top = "io.github.kirillshchetinnikov.cutelauncher/com.leanbitlab.ltvL.MainActivity";
        final List<String> writes = new ArrayList<>();
        public String execute(String command) {
            if (command.equals("dumpsys activity activities"))
                return "    topResumedActivity=ActivityRecord{abc u0 " + top + " t5}\n";
            writes.add(command); return "";
        }
    }
    @Test public void startsOnlyNamedClientAndReturnsToOriginalScreen() throws Exception {
        var shell = new Shell(); String previous = shell.top;
        var session = VpnStartupRecovery.begin(shell, 0, APP, APP + "/.activity.MainActivity");
        assertEquals(1, shell.writes.size());
        assertTrue(shell.writes.get(0).contains("'" + APP + "/.activity.MainActivity'"));
        shell.top = APP + "/.activity.MainActivity";
        VpnStartupRecovery.restore(shell, 0, session);
        assertEquals(2, shell.writes.size());
        assertTrue(shell.writes.get(1).contains("'" + previous + "'"));
    }
    @Test public void doesNotOverrideUserNavigation() throws Exception {
        var shell = new Shell();
        var session = VpnStartupRecovery.begin(shell, 0, APP, APP + "/.activity.MainActivity");
        shell.top = "another.app/.MainActivity";
        VpnStartupRecovery.restore(shell, 0, session);
        assertEquals(1, shell.writes.size());
    }
    @Test public void cancellationDuringAdbReadPreventsActivityLaunch() {
        var valid = new java.util.concurrent.atomic.AtomicBoolean(true);
        var writes = new ArrayList<String>();
        VpnStartupRecovery.Shell shell = command -> {
            if (command.equals("dumpsys activity activities")) {
                valid.set(false);
                return "topResumedActivity=ActivityRecord{abc u0 another.app/.Main t5}\n";
            }
            writes.add(command); return "";
        };
        assertThrows(java.util.concurrent.CancellationException.class,
            () -> VpnStartupRecovery.begin(shell, 0, APP, APP + "/.Main", valid::get));
        assertTrue(writes.isEmpty());
    }
    @Test public void rejectsInvalidTargetsAndMissingPreviousScreen() {
        var shell = new Shell();
        assertThrows(IllegalArgumentException.class, () -> VpnStartupRecovery.begin(shell, 0, APP, "other.app/.Main"));
        assertThrows(IllegalArgumentException.class, () -> VpnStartupRecovery.begin(shell, 0, APP, APP + "/.Main';bad"));
        shell.top = "";
        assertThrows(IllegalStateException.class, () -> VpnStartupRecovery.begin(shell, 0, APP, APP + "/.Main"));
        assertTrue(shell.writes.isEmpty());
    }
}
