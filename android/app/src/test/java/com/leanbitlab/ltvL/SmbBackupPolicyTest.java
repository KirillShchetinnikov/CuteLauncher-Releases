package com.leanbitlab.ltvL;

import com.hierynomus.mssmb2.SMB2Dialect;
import java.net.Socket;
import java.net.ServerSocket;
import java.util.Set;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class SmbBackupPolicyTest {
    private static final String NAME = "cute-backup-shared-" + "a".repeat(32) + "-123-" + "b".repeat(16) + ".json";
    @Test public void acceptsShareRootSubfoldersUnicodeAndExplicitPort() throws Exception {
        var root = new SmbBackupPolicy("smb://nas/share");
        assertEquals("share", root.share); assertEquals("", root.folder); assertEquals(445, root.port);
        var nested = new SmbBackupPolicy("smb://nas:1445/share/TV backups/Копии/");
        assertEquals("nas", nested.host); assertEquals(1445, nested.port);
        assertEquals("TV backups\\Копии", nested.folder);
        assertEquals("TV backups\\Копии\\" + NAME, nested.path(NAME, false));
    }
    @Test public void rejectsTraversalCredentialsAndAlternateStreams() {
        for (String value : new String[] {"https://nas/share", "smb://nas", "smb://user:pass@nas/share",
                "smb://nas/share/../other", "smb://nas/share/%2e%2e/other", "smb://nas/share/a%2fb",
                "smb://nas/share/a%5cb", "smb://nas/share/file:stream", "smb://nas/share//folder",
                "smb://nas/share?password=secret", "smb://nas/share#fragment", "smb://nas:0/share",
                "smb://nas/share/%00", "smb://nas/share/trailing.", "smb://nas/share/trailing%20"}) {
            assertThrows(value, Exception.class, () -> new SmbBackupPolicy(value));
        }
    }
    @Test public void fileOperationsOnlyAcceptOwnedNames() throws Exception {
        var target = new SmbBackupPolicy("smb://nas/share/backups");
        assertTrue(SmbBackupPolicy.validName(NAME, false));
        assertTrue(SmbBackupPolicy.validName(NAME + ".partial", true));
        assertFalse(SmbBackupPolicy.validName(NAME + ".partial", false));
        assertFalse(SmbBackupPolicy.validName(NAME, true));
        assertFalse(SmbBackupPolicy.validName(NAME.replace("-123-", "-" + "9".repeat(40) + "-"), false));
        assertThrows(IllegalArgumentException.class, () -> target.path("../" + NAME, false));
        assertThrows(IllegalArgumentException.class, () -> target.path("personal.txt", false));
    }
    @Test public void negotiatesOnlySmb2And3WithSigningAndNoDfs() throws Exception {
        var config = SmbBackupBridge.config(new SmbBackupBridge.Job(), new SmbBackupPolicy("smb://nas/share"));
        assertEquals(Set.of(SMB2Dialect.SMB_2_0_2, SMB2Dialect.SMB_2_1, SMB2Dialect.SMB_3_0,
            SMB2Dialect.SMB_3_0_2, SMB2Dialect.SMB_3_1_1), config.getSupportedDialects());
        assertTrue(config.isSigningRequired()); assertFalse(config.isDfsEnabled());
        assertEquals(1, config.getSupportedAuthenticators().size());
    }
    @Test public void cancellationClosesSocketAndForbidsServerRedirect() throws Exception {
        try (ServerSocket server = new ServerSocket(0)) {
            var target = new SmbBackupPolicy("smb://127.0.0.1:" + server.getLocalPort() + "/share");
            var job = new SmbBackupBridge.Job();
            var factory = SmbBackupBridge.config(job, target).getSocketFactory();
            try (Socket socket = factory.createSocket(target.host, target.port); Socket peer = server.accept()) {
                job.cancel(false);
                assertTrue(socket.isClosed());
                assertThrows(java.io.IOException.class, job::check);
            }
            assertThrows(java.io.IOException.class, () -> factory.createSocket("other-server", 445));
        }
    }
    @Test public void serverCannotDowngradeLoginToGuestOrAnonymous() throws Exception {
        SmbBackupBridge.requireAuthenticated(false, false);
        assertThrows(SmbBackupBridge.Failure.class, () -> SmbBackupBridge.requireAuthenticated(true, false));
        assertThrows(SmbBackupBridge.Failure.class, () -> SmbBackupBridge.requireAuthenticated(false, true));
    }
    @Test public void nativeTransfersCannotReadAccountVaultOrOutsideFiles() throws Exception {
        var app = RuntimeEnvironment.getApplication();
        assertThrows(SecurityException.class, () -> SmbBackupBridge.localFile(app,
            new java.io.File(app.getNoBackupFilesDir(), "cloud/smb").getPath()));
        assertThrows(SecurityException.class, () -> SmbBackupBridge.localFile(app,
            new java.io.File(app.getCacheDir(), "../outside").getPath()));
        assertEquals(new java.io.File(app.getCacheDir(), "backup.partial").getCanonicalFile(),
            SmbBackupBridge.localFile(app, new java.io.File(app.getCacheDir(), "backup.partial").getPath()));
    }
}
