package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.CancellationSignal;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import androidx.core.location.LocationManagerCompat;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** One foreground request; approximate location is sufficient for weather. */
final class WeatherLocationBridge {
    static final int PERMISSION_REQUEST = 2402;
    private final Activity activity;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final MethodChannel channel;
    private MethodChannel.Result pending;
    private final List<CancellationSignal> cancellations = new ArrayList<>();
    private Runnable timeout;
    private long generation;
    private int remaining;

    WeatherLocationBridge(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        channel = new MethodChannel(messenger, "cutelauncher/weather_location");
        channel.setMethodCallHandler((call, result) -> {
            if (!call.method.equals("locate")) { result.notImplemented(); return; }
            if (pending != null) { result.error("BUSY", "Location request in progress", null); return; }
            pending = result; generation++;
            if (activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                activity.requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST);
            } else locate();
        });
    }

    void onPermissionResult() {
        if (pending == null) return;
        if (activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) locate();
        else finish(null, "LOCATION_PERMISSION_DENIED");
    }

    static long ageMillis(Location location) {
        return (SystemClock.elapsedRealtimeNanos()-location.getElapsedRealtimeNanos())/1000000;
    }

    static boolean usable(Location location) {
        return location != null && location.hasAccuracy() && LocationFixPolicy.usable(
            location.getLatitude(),location.getLongitude(),location.getAccuracy(),ageMillis(location));
    }

    private void locate() {
        final long request=generation;
        try {
            LocationManager manager = activity.getSystemService(LocationManager.class);
            if (manager == null || !manager.isLocationEnabled()) { finish(null, "LOCATION_UNAVAILABLE",request); return; }
            List<String> providers=new ArrayList<>();
            if (manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) providers.add(LocationManager.NETWORK_PROVIDER);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && manager.isProviderEnabled(LocationManager.FUSED_PROVIDER))
                providers.add(LocationManager.FUSED_PROVIDER);
            Location cached=null;
            for (String provider : providers) {
                Location value=manager.getLastKnownLocation(provider);
                if (usable(value) && (cached == null || ageMillis(value)<ageMillis(cached))) cached=value;
            }
            if (cached != null) { finish(cached,null,request); return; }
            if (providers.isEmpty()) { finish(null,"LOCATION_UNAVAILABLE",request); return; }
            remaining=providers.size();
            timeout=() -> finish(null,"LOCATION_UNAVAILABLE",request);
            handler.postDelayed(timeout,20000);
            for (String provider : providers) {
                CancellationSignal signal=new CancellationSignal(); cancellations.add(signal);
                try {
                    LocationManagerCompat.getCurrentLocation(manager,provider,signal,activity.getMainExecutor(), location -> {
                        if (request != generation || pending == null) return;
                        if (usable(location)) finish(location,null,request);
                        else if (--remaining == 0) finish(null,"LOCATION_UNAVAILABLE",request);
                    });
                } catch (SecurityException e) { finish(null,"LOCATION_PERMISSION_DENIED",request); return; }
                catch (RuntimeException e) { if (--remaining == 0) finish(null,"LOCATION_UNAVAILABLE",request); }
            }
        } catch (SecurityException e) { finish(null,"LOCATION_PERMISSION_DENIED",request); }
        catch (RuntimeException e) { finish(null,"LOCATION_UNAVAILABLE",request); }
    }

    private void finish(Location location, String error) { finish(location,error,generation); }

    private void finish(Location location, String error, long request) {
        if (request != generation || pending == null) return;
        if (timeout != null) { handler.removeCallbacks(timeout); timeout=null; }
        MethodChannel.Result result=pending; pending=null;
        for (CancellationSignal signal : cancellations) signal.cancel();
        cancellations.clear();
        if (location == null) result.error(error, "Could not obtain weather location", null);
        else result.success(Map.of("latitude",location.getLatitude(),"longitude",location.getLongitude()));
    }

    void dispose() {
        channel.setMethodCallHandler(null);
        finish(null, "LOCATION_UNAVAILABLE");
    }
}
