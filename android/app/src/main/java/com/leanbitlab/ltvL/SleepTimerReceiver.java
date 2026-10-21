package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class SleepTimerReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        PendingResult pending = goAsync();
        SleepTimerBridge.expire(context.getApplicationContext(), intent.getLongExtra("deadline", 0), pending::finish);
    }
}
