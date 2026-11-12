package com.leanbitlab.ltvL;

import java.io.File;
import java.nio.file.Files;
import java.nio.charset.StandardCharsets;
import org.junit.Test;
import static org.junit.Assert.*;

public class BackupDataCipherTest {
    @Test public void wholeFileRoundTripAndOptionalPassword() throws Exception {
        File f=File.createTempFile("backup-cipher-", ".json");
        try {
            String clear="{\"settings\":{\"token\":\"test-only-token\",\"name\":\"Телевизор\"}}";
            Files.write(f.toPath(),clear.getBytes(StandardCharsets.UTF_8));
            BackupDataCipher.transform(f,"",true);assertEquals(clear,new String(Files.readAllBytes(f.toPath()),StandardCharsets.UTF_8));
            BackupDataCipher.transform(f,"пример пароля",true);assertTrue(BackupDataCipher.encrypted(f));
            byte[] first=Files.readAllBytes(f.toPath());assertFalse(new String(first,StandardCharsets.UTF_8).contains("test-only-token"));
            assertThrows(Exception.class,()->BackupDataCipher.transform(f,"wrong",false));
            assertArrayEquals(first,Files.readAllBytes(f.toPath()));assertFalse(new File(f+".crypt").exists());
            BackupDataCipher.transform(f,"пример пароля",false);assertEquals(clear,new String(Files.readAllBytes(f.toPath()),StandardCharsets.UTF_8));
            BackupDataCipher.transform(f,"пример пароля",true);assertFalse(java.util.Arrays.equals(first,Files.readAllBytes(f.toPath())));
            byte[] altered=Files.readAllBytes(f.toPath());altered[altered.length-1]^=1;Files.write(f.toPath(),altered);
            assertThrows(Exception.class,()->BackupDataCipher.transform(f,"пример пароля",false));assertArrayEquals(altered,Files.readAllBytes(f.toPath()));
        } finally {Files.deleteIfExists(f.toPath());}
    }
    @Test public void rejectsUnboundedWorkAndInvalidProfilePaths() throws Exception {
        assertEquals("default",BackupAccountProfile.id(null));
        assertEquals("a".repeat(32),BackupAccountProfile.id("a".repeat(32)));
        assertThrows(IllegalArgumentException.class,()->BackupAccountProfile.id("../../other"));
        File f=File.createTempFile("backup-header-", ".json");
        try {
            Files.write(f.toPath(),new byte[]{'C','U','T','E','E','N','C','1',127,127,127,127});
            assertThrows(IllegalArgumentException.class,()->BackupDataCipher.transform(f,"password",false));
            assertFalse(new File(f+".crypt").exists());
        }finally{Files.deleteIfExists(f.toPath());}
    }
}
