package com.leanbitlab.ltvL;

import java.util.Set;

public final class TclPictureModeTest {
    public static final class Reader {
        Object value;
        boolean fail;
        public Object getPictureMode() {
            if (fail) throw new IllegalStateException("Service unavailable");
            return value;
        }
    }
    public static void main(String[] args) throws Exception {
        Reader reader = new Reader();
        var method = Reader.class.getMethod("getPictureMode");
        for (int mode : new int[]{0, 3, 19, 29, 51, 60, 255}) {
            reader.value = mode;
            require(TclPictureMode.read(reader, method).equals(mode), "Read current mode");
        }
        for (Object invalid : new Object[]{null, -1, 256, "19", 19L}) {
            reader.value = invalid;
            require(TclPictureMode.read(reader, method) == null, "Invalid reading never reused");
        }
        reader.fail = true;
        require(TclPictureMode.read(reader, method) == null, "OEM failure is safe");
        require(TclPictureMode.read() == null, "Missing optional library is supported");
        require(!TclPictureMode.excluded(19, Set.of()), "Default excludes nothing");
        require(TclPictureMode.excluded(19, Set.of(19, 51)), "Selected HDR mode");
        require(!TclPictureMode.excluded(3, Set.of(19, 51)), "SDR movie stays filtered");
        require(TclPictureMode.excluded(51, Set.of(19, 51)), "Selected Dolby Vision mode");
        require(!TclPictureMode.excluded(null, Set.of(19)), "Unavailable mode stays filtered");
        System.out.println("TclPictureModeTest passed");
    }
    private static void require(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }
}
