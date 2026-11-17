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

public class NetworkEventStreamHandler implements EventChannel.StreamHandler, AutoCloseable
{
    private final ConnectivityManager _connectivityManager;
    private final Context _context;
    private final Handler _handler;
    private ConnectivityManager.NetworkCallback _networkCallback;

    public NetworkEventStreamHandler(Context context)
    {
        _connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        _context = context.getApplicationContext();
        _handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        close();
        try {
            _networkCallback = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                    ? new NetworkCallbackImplApi31(events, null)
                    : new NetworkCallbackImpl(events, null);
            _connectivityManager.registerDefaultNetworkCallback(_networkCallback, _handler);
        }
        catch (RuntimeException e) {
            close();
            e.printStackTrace();
        }
    }

    @Override
    public void onCancel(Object arguments) {
        close();
    }

    @Override public void close() {
        var callback = _networkCallback;
        _networkCallback = null; // Invalidate queued network/telephony events before unregistering.
        if (callback != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                    && callback instanceof NetworkCallbackImplApi31) {
                ((NetworkCallbackImplApi31) callback).stopTelephony();
            }
            try { _connectivityManager.unregisterNetworkCallback(callback); }
            catch (IllegalArgumentException ignored) { }
        }
        _handler.removeCallbacksAndMessages(null);
    }

    private class NetworkCallbackImpl extends ConnectivityManager.NetworkCallback
    {
        protected final EventChannel.EventSink    _eventSink;
        protected final Handler                   _handler;

        public NetworkCallbackImpl(EventChannel.EventSink eventSink, Handler handler)
        {
            _eventSink = new EventChannel.EventSink() {
                public void success(Object event) {
                    if (NetworkCallbackImpl.this == _networkCallback) eventSink.success(event);
                }
                public void error(String code, String message, Object details) {
                    if (NetworkCallbackImpl.this == _networkCallback) eventSink.error(code, message, details);
                }
                public void endOfStream() {
                    if (NetworkCallbackImpl.this == _networkCallback) eventSink.endOfStream();
                }
            };
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
            if (this != _networkCallback) return;
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);
            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_AVAILABLE"); put("arguments", map); }});
        }

        @Override
        public void onCapabilitiesChanged(@NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
            if (this != _networkCallback) return;
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);

            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "CAPABILITIES_CHANGED"); put("arguments", map); }});
        }

        @Override
        public void onLost(@NonNull Network network) {
            if (this != _networkCallback) return;
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
            if (this != _networkCallback) return;
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);
            postEvent(new java.util.HashMap<String, Object>() {{ put("name", "NETWORK_AVAILABLE"); put("arguments", map); }});
        }

        @Override
        public void onCapabilitiesChanged(@NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
            if (this != _networkCallback) return;
            Map<String, Object> map = NetworkUtils.getNetworkInformation(_context, network);

            if (Objects.equals(map.get(NetworkUtils.KEY_NETWORK_TYPE), NetworkUtils.NETWORK_TYPE_CELLULAR)) {
                TelephonyManager manager = (TelephonyManager) _context.getSystemService(Context.TELEPHONY_SERVICE);

                if (manager != null && _telephonyCallback == null) {
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
            if (this != _networkCallback) return;
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


