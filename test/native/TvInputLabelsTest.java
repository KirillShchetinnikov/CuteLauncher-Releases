package com.leanbitlab.ltvL;

import java.util.Objects;

public final class TvInputLabelsTest {
    static void equal(String expected, String actual) {
        if (!Objects.equals(expected, actual))
            throw new AssertionError("Expected " + expected + ", got " + actual);
    }
    public static void main(String[] args) {
        for (String vendor : new String[]{"Philips", "PHILIPS", "TP Vision", "TPV", "TPVision"}) {
            equal("Xbox", TvInputLabels.customLabel("Xbox&GAME_CONSOLE", vendor, ""));
            equal("Ordinateur", TvInputLabels.customLabel(" Ordinateur &COMPUTER ", vendor, ""));
            equal("Приставка", TvInputLabels.customLabel("Приставка&SET_TOP_BOX", vendor, ""));
            equal("Box", TvInputLabels.customLabel("Box&SOMETHING_NEW", vendor, ""));
            equal("Tom & Jerry", TvInputLabels.customLabel("Tom & Jerry&COMPUTER", vendor, ""));
            equal("Tom & Jerry", TvInputLabels.customLabel("Tom & Jerry", vendor, ""));
            equal("AT&T", TvInputLabels.customLabel("AT&T", vendor, ""));
            equal("R&D", TvInputLabels.customLabel("R&D", vendor, ""));
            equal("PC&computer", TvInputLabels.customLabel("PC&computer", vendor, ""));
            for (String absent : new String[]{null, "", " ", "null", " null ", "&GAME_CONSOLE", "null&COMPUTER"})
                equal(null, TvInputLabels.customLabel(absent, vendor, ""));
        }
        equal("Xbox", TvInputLabels.customLabel("Xbox&GAME_CONSOLE", "unknown", "Philips"));
        for (String vendor : new String[]{"TCL", "Sony", "", null}) {
            equal("Xbox&GAME_CONSOLE", TvInputLabels.customLabel("Xbox&GAME_CONSOLE", vendor, null));
            equal("null", TvInputLabels.customLabel("null", vendor, ""));
            equal(null, TvInputLabels.customLabel(null, vendor, ""));
        }
        System.out.println("TvInputLabelsTest passed");
    }
}
