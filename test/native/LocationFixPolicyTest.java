package com.leanbitlab.ltvL;

public final class LocationFixPolicyTest {
    public static void main(String[] args) {
        if (!LocationFixPolicy.usable(54,36,2000,30*60*1000L)) throw new AssertionError("TV cache must work");
        for (long age : new long[]{-1,24*60*60*1000L+1})
            if (LocationFixPolicy.usable(54,36,2000,age)) throw new AssertionError("Invalid age accepted");
        if (LocationFixPolicy.usable(Double.NaN,36,20,0) || LocationFixPolicy.usable(91,36,20,0) ||
            LocationFixPolicy.usable(54,181,20,0) || LocationFixPolicy.usable(54,36,100001,0))
            throw new AssertionError("Invalid fix accepted");
        System.out.println("LocationFixPolicyTest passed");
    }
}
