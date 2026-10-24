package com.leanbitlab.ltvL;

import java.nio.file.Files;
import java.nio.file.Path;

public final class EthernetUsageHistoryTest {
    private static final String HEADER = "v1,0,20000\nxt\n";
    private static final String ETH = "c,eth,-1,all,0\nd,3600\n";
    private static final String DATA = HEADER + ETH + "b,0,3600,1,3600,1,0\nb,3600,7200,1,3600,1,0\n";
    private static int cases;
    private static void expect(long expected, long actual) {
        cases++;
        if (actual != expected) throw new AssertionError("Expected " + expected + ", got " + actual);
    }
    private static void invalid(String text) {
        cases++;
        try { EthernetUsageHistory.parse(text); }
        catch (IllegalArgumentException | ArithmeticException expected) { return; }
        throw new AssertionError("Accepted invalid history");
    }
    public static void main(String[] args) throws Exception {
        if (args.length == 3) {
            var history = EthernetUsageHistory.parse(Files.readString(Path.of(args[0])));
            System.out.println("Ethernet bytes: " + history.usage(Long.parseLong(args[1]), Long.parseLong(args[2])));
            return;
        }
        var history = EthernetUsageHistory.parse(DATA);
        expect(18000, history.usage(0, 7200000));
        expect(9000, history.usage(1800000, 5400000));
        expect(7200, history.usage(0, 3600000));
        expect(10800, history.usage(3600000, 7200000));
        expect(0, history.usage(7200000, 8000000));
        expect(-2, history.usage(-1, 3600000));
        expect(-2, history.usage(20000001, 20000002));
        expect(0, EthernetUsageHistory.parse(HEADER + ETH + "b,0,0,0,0,0,0\n").usage(0, 1000));
        expect(18000, EthernetUsageHistory.parse(DATA + "c,wifi,-1,all,0\nd,3600\nb,0,999999,0,999999,0,0\n").usage(0, 7200000));
        invalid("Permission Denial\n");
        invalid(DATA.trim());
        invalid(DATA.replace("v1", "v2"));
        invalid(DATA.replace("xt\n", ""));
        invalid(DATA.replace("c,eth,-1,all,0", "c,eth,123,all,0"));
        invalid(DATA.replace("c,eth,-1,all,0", "c,eth,-1,all,123"));
        invalid(DATA.replace("d,3600\n", ""));
        invalid(DATA.replace("d,3600", "d,0"));
        invalid(DATA.replace("b,3600", "b,0"));
        invalid(DATA.replace("b,3600", "b,1800"));
        invalid(DATA.replace("b,0,3600", "b,0,-1"));
        invalid(DATA.replace("b,0,3600", "b,0,*"));
        invalid(DATA + ETH + "b,0,1,0,1,0,0\n");
        invalid(DATA + "uid\n" + ETH + "b,0,1,0,1,0,0\n");
        invalid(DATA + "Exception occurred while dumping: broken firmware\n");
        invalid(HEADER + "c,wifi,-1,all,0\nd,3600\nb,0,1,0,1,0,0\n");
        invalid(HEADER + ETH);
        invalid(DATA.replace("b,0,3600,1,3600", "b,0,9223372036854775807,1,1"));
        invalid(DATA + "x".repeat(EthernetUsageHistory.MAX_OUTPUT));
        int[] loads = {0};
        var cache = new EthernetUsageCache();
        EthernetUsageCache.Loader loader = () -> { loads[0]++; return DATA; };
        expect(7200, cache.read(0, 3600000, 1000, loader));
        expect(18000, cache.read(0, 7200000, 2000, loader));
        expect(1, loads[0]);
        expect(18000, cache.read(0, 7200000, 301000, loader));
        expect(2, loads[0]);
        expect(-2, cache.read(0, 7200000, 601000, () -> { loads[0]++; throw new Exception("offline"); }));
        expect(-2, cache.read(0, 7200000, 602000, loader));
        expect(3, loads[0]);
        expect(18000, cache.read(0, 7200000, 661000, loader));
        expect(4, loads[0]);
        System.out.println("Ethernet history/cache: " + cases + " cases passed");
    }
}
