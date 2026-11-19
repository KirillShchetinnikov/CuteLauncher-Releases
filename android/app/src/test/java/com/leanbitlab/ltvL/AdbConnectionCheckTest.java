package com.leanbitlab.ltvL;

import dadb.AdbKeyPair;
import java.io.DataInputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Arrays;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import static org.junit.Assert.*;

public class AdbConnectionCheckTest {
    private static final int CNXN = 0x4e584e43;
    private static final int AUTH = 0x48545541;

    @Rule public TemporaryFolder keysDir = new TemporaryFolder();

    @Test public void firstCheckRecoversFromDroppedHandshakeAndOffersNewKey() throws Exception {
        var privateKey = keysDir.newFile("private-key");
        var publicKey = keysDir.newFile("public-key");
        AdbKeyPair.generate(privateKey, publicKey);
        byte[] savedPublicKey = Files.readAllBytes(publicKey.toPath());
        var executor = Executors.newSingleThreadExecutor();
        try (var listener = new ServerSocket(0, 2, InetAddress.getByName("127.0.0.1"))) {
            listener.setSoTimeout(4000);
            var peer = executor.submit(() -> {
                // The listener can accept before adbd is ready to complete a handshake.
                try (var socket = listener.accept()) {
                    readPacket(socket, CNXN, null);
                }
                try (var socket = listener.accept()) {
                    readPacket(socket, CNXN, null);
                    sendPacket(socket, AUTH, 1, 0, new byte[20]);
                    assertEquals(256, readPacket(socket, AUTH, 2).length);
                    sendPacket(socket, AUTH, 1, 0, new byte[20]);
                    assertArrayEquals(Arrays.copyOf(savedPublicKey, savedPublicKey.length + 1),
                        readPacket(socket, AUTH, 3));
                    // The test peer completes authentication after receiving the public key.
                    sendPacket(socket, CNXN, 0x01000001, 4096,
                        "device::features=shell_v2;".getBytes(StandardCharsets.UTF_8));
                }
                return null;
            });
            try (var adb = AdbBridge.connectForCheck(listener.getLocalPort(), AdbKeyPair.read(privateKey, publicKey))) {
                assertTrue(adb.supportsFeature("shell_v2"));
            }
            peer.get(4, TimeUnit.SECONDS);
        } finally {
            executor.shutdownNow();
        }
    }

    static byte[] readPacket(Socket socket, int command, Integer arg0) throws IOException {
        socket.setSoTimeout(4000);
        var input = new DataInputStream(socket.getInputStream());
        assertEquals(command, Integer.reverseBytes(input.readInt()));
        int firstArgument = Integer.reverseBytes(input.readInt());
        if (arg0 != null) assertEquals(arg0.intValue(), firstArgument);
        input.readInt();
        int length = Integer.reverseBytes(input.readInt());
        assertTrue(length >= 0 && length <= 4096);
        input.readInt();
        input.readInt();
        return input.readNBytes(length);
    }

    static void sendPacket(Socket socket, int command, int arg0, int arg1, byte[] payload) throws IOException {
        int checksum = 0;
        for (byte value : payload) checksum += value & 0xff;
        socket.getOutputStream().write(ByteBuffer.allocate(24 + payload.length).order(ByteOrder.LITTLE_ENDIAN)
            .putInt(command).putInt(arg0).putInt(arg1).putInt(payload.length).putInt(checksum).putInt(~command)
            .put(payload).array());
    }
}
