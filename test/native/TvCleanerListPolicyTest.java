package com.leanbitlab.ltvL;

import java.util.*;

public final class TvCleanerListPolicyTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        var installed = Map.of(
            "org.example.system", new TvCleanerListPolicy.App(true,false,true,false),
            "org.example.user", new TvCleanerListPolicy.App(false,false,true,false),
            "org.example.preinstalled", new TvCleanerListPolicy.App(true,true,true,false),
            "org.example.off", new TvCleanerListPolicy.App(true,false,false,false),
            "org.example.protected", new TvCleanerListPolicy.App(true,false,true,true));
        var names = List.of("org.example.system","org.example.user","org.example.preinstalled",
            "org.example.off","org.example.protected","org.example.missing","org.example.system");
        check(TvCleanerListPolicy.select(names,installed,"system",false).equals(List.of("org.example.system")));
        check(TvCleanerListPolicy.select(names,installed,"preinstalled",false).equals(List.of("org.example.preinstalled")));
        check(TvCleanerListPolicy.select(names,installed,null,false).equals(List.of("org.example.system","org.example.user","org.example.preinstalled")));
        check(TvCleanerListPolicy.select(names,installed,"system",true).equals(List.of("org.example.off")));
        for (String invalid : List.of("../x", "org.example.a;reboot", "org.example.a/Activity")) {
            try { TvCleanerListPolicy.select(List.of("org.example.system",invalid),installed,null,false); throw new AssertionError(); }
            catch (IllegalArgumentException expected) { }
        }
        try { TvCleanerListPolicy.select(names,installed,"user",false); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        System.out.println("TvCleanerListPolicyTest passed");
    }
}
