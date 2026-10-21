package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.SystemClock;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/** Read-only OEM diagnostics. Does not change settings, providers, or app preferences. */
public final class LocationDiagnosticProbe extends Instrumentation {
    private Bundle args;
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); args=arguments; start(); }
    @Override public void onStart() {
        Bundle result=new Bundle();
        try {
            LocationManager manager=getTargetContext().getSystemService(LocationManager.class);
            result.putBoolean("locationEnabled",manager.isLocationEnabled());
            for (String provider : new String[]{"network","fused"}) {
                if (!manager.isProviderEnabled(provider)) continue;
                Location cached=manager.getLastKnownLocation(provider);
                result.putString(provider+"Cached",cached == null ? "none" :
                    "ageMs="+(SystemClock.elapsedRealtimeNanos()-cached.getElapsedRealtimeNanos())/1000000+
                    ", accuracy="+cached.getAccuracy());
                for (int i=0;i<2;i++) {
                    CountDownLatch done=new CountDownLatch(1);
                    CancellationSignal cancel=new CancellationSignal();
                    final Location[] received={null};
                    manager.getCurrentLocation(provider,cancel,getTargetContext().getMainExecutor(),value -> {
                        received[0]=value; done.countDown();
                    });
                    boolean responded=done.await(16,TimeUnit.SECONDS); cancel.cancel();
                    result.putString(provider+"Current"+i,!responded ? "timeout" : received[0] == null ? "null" : "fix");
                }
            }
            result.putString("result","diagnostic complete"); finish(-1,result);
        } catch (Exception e) { result.putString("error",e.toString()); finish(0,result); }
    }
}
