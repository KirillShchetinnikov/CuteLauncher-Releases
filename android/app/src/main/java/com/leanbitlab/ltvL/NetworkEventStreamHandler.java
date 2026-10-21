package com.leanbitlab.ltvL;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telephony.TelephonyManager;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.Map;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;

public class NetworkEventStreamHandler implements EventChannel.StreamHandler
{
    private final ConnectivityManager _connectivityManager;
    private final Context _context;
    private final Handler _handler;
    private ConnectivityManager.NetworkCallback _networkCallback;

    public NetworkEventStreamHandler(Context context)
    {
        _connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        _context = context;
        _handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {

        try {
            _networkCallback = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                    ? new NetworkCallbackImplApi31(events, null)
                    : new NetworkCallbackImpl(events, null);
            _connectivityManager.registerDefaultNetworkCallback(_networkCallback, _handler);
        }
        catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onCancel(Object arguments) {
        if (_networkCallback != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                    && _networkCallback instanceof NetworkCallbackImplApi31) {
                ((NetworkCallbackImplApi31) _networkCallback).stopTelephony();
            }
            try { _connectivityManager.unregisterNetworkCallback(_networkCallback); }
            catch (IllegalArgumentException ignored) { }
            _networkCallback = null;
        }
    }

    private class NetworkCallbackImpl extends ConnectivityManager.NetworkCallback
    {
        protected final EventChannel.EventSink    _eventSink;
        protected final Handler                   _handler;

        public NetworkCallbackImpl(EventChannel.EventSink eventSink, Handler handler)
        {
            _eventSink = eventSink;
            _handler = handler;
        }

        protected void postEvent(Map<String, Object> map)
        {
            if (_handler != null) {
                _handler.post(() -> _eventSink.success(map));
            }
            else {
                _eventSink.success(map);
            }
        }

        @Override
        public void onAvailable(@NonNull Network network) {
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);
            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_AVAILABLE"); put("arguments", map); }});
        }

        @Override
        public void onCapabilitiesChanged(@NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);

            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "CAPABILITIES_CHANGED"); put("arguments", map); }});
        }

        @Override
        public void onLost(@NonNull Network network) {
            Network activeNetwork = _connectivityManager.getActiveNetwork();
            if (activeNetwork == null) {
                postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_UNAVAILABLE"); }});
            } else {
                Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, activeNetwork);
                postEvent(new java.util.HashMap<String, Object>() {{ put("name", "CAPABILITIES_CHANGED"); put("arguments", map); }});
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private class NetworkCallbackImplApi31 extends NetworkCallbackImpl
    {
        private TelephonyCallbackImpl _telephonyCallback;

        private void stopTelephony() {
            if (_telephonyCallback != null) {
                TelephonyManager manager = (TelephonyManager) _context.getSystemService(Context.TELEPHONY_SERVICE);
                if (manager != null) manager.unregisterTelephonyCallback(_telephonyCallback);
                _telephonyCallback = null;
            }
        }

        public NetworkCallbackImplApi31(EventChannel.EventSink eventSink, Handler handler)
        {
            super(eventSink, handler);
        }

        @Override
        public void onAvailable(@NonNull Network network) {
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);
            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_AVAILABLE"); put("arguments", map); }});
        }

        @Override
        public void onCapabilitiesChanged(@NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);

            if (Objects.equals(map.get(NetworkUtils.KEY_NETWORK_TYPE), NetworkUtils.NETWORK_TYPE_CELLULAR)) {
                TelephonyManager manager = (TelephonyManager) _context.getSystemService(Context.TELEPHONY_SERVICE);

                if (_telephonyCallback == null) {
                    _telephonyCallback = new TelephonyCallbackImpl(_eventSink);
                    try {
                        manager.registerTelephonyCallback(_context.getMainExecutor(), _telephonyCallback);
                    } catch (SecurityException ignored) { }
                }
            }

            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "CAPABILITIES_CHANGED"); put("arguments", map); }});
        }

        @Override
        public void onLost(@NonNull Network network) {
            stopTelephony();

            Network activeNetwork = _connectivityManager.getActiveNetwork();
            if (activeNetwork == null) {
                postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_UNAVAILABLE"); }});
            } else {
                Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, activeNetwork);
                postEvent(new java.util.HashMap<String, Object>() {{ put("name", "CAPABILITIES_CHANGED"); put("arguments", map); }});
            }
        }
    }
}


