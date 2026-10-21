package com.leanbitlab.ltvL;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

final class BoundedImageInput {
    static final int MAX_BYTES = 8 * 1024 * 1024;
    static byte[] read(InputStream input, int limit) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream(Math.min(limit, 8192));
        byte[] chunk = new byte[8192];
        int count;
        while ((count = input.read(chunk)) != -1) {
            if ((long) bytes.size() + count > limit) throw new IOException("Image too large");
            bytes.write(chunk, 0, count);
        }
        return bytes.toByteArray();
    }
}
