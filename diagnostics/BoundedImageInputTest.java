package com.leanbitlab.ltvL;
import java.io.*;
public final class BoundedImageInputTest {
    public static void main(String[] args) throws Exception {
        if (BoundedImageInput.read(new ByteArrayInputStream(new byte[4]), 4).length != 4)
            throw new AssertionError("Exact limit refused");
        try {
            BoundedImageInput.read(new ByteArrayInputStream(new byte[5]), 4);
            throw new AssertionError("Oversized input accepted");
        } catch (IOException expected) { }
        if (BoundedImageInput.read(new ByteArrayInputStream(new byte[0]), 4).length != 0)
            throw new AssertionError("Empty input handling");
        System.out.println("Bounded image checks passed");
    }
}
