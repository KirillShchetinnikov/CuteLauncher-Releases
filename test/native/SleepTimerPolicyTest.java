package com.leanbitlab.ltvL;

public class SleepTimerPolicyTest {
    private static void require(boolean ok, String message) {
        if (!ok) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        for (int m : new int[]{1,10,11,20,30,40,50,60,61,90,120,150,180,240,300,360,361,1440})
            require(SleepTimerPolicy.validMinutes(m), "Duration " + m);
        for (int m : new int[]{-1,0,Integer.MAX_VALUE})
            require(!SleepTimerPolicy.validMinutes(m), "Reject duration " + m);
        for (long seconds : new long[]{1, 30, 31, 21601, 3599999999L})
            require(SleepTimerPolicy.validSeconds(seconds), "Custom seconds " + seconds);
        for (long seconds : new long[]{-1, 0, 3600000000L, Long.MAX_VALUE})
            require(!SleepTimerPolicy.validSeconds(seconds), "Reject seconds " + seconds);
        require(!SleepTimerPolicy.due(600,600,1,1,599), "Never fire early");
        require(SleepTimerPolicy.due(600,600,1,1,600), "Deadline inclusive");
        require(SleepTimerPolicy.due(600,600,1,1,900), "Late alarm still fires");
        require(!SleepTimerPolicy.due(1200,600,1,1,1300), "Restart invalidates old delivery");
        require(!SleepTimerPolicy.due(0,600,1,1,900), "Cancellation invalidates delivery");
        require(!SleepTimerPolicy.due(0,0,1,1,900), "Absent alarm cannot fire");
        require(!SleepTimerPolicy.due(600,600,1,2,900), "Reboot invalidates elapsed deadline");
        System.out.println("SleepTimerPolicy: all checks passed");
    }
}
