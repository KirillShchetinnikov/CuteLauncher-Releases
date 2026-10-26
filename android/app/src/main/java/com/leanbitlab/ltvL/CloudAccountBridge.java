package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.util.Map;
import java.util.concurrent.Executor;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

final class CloudAccountBridge {
    private static final java.util.concurrent.atomic.AtomicLong revision = new java.util.concurrent.atomic.AtomicLong();
    private static final Object mutationLock = new Object();
    static void register(Context context,BinaryMessenger messenger,Executor executor) {
        CloudAccountStore store=new CloudAccountStore(context.getApplicationContext());
        Handler main=new Handler(Looper.getMainLooper());
        new MethodChannel(messenger,"cutelauncher/cloud_account").setMethodCallHandler((call,result) -> {
            if(!java.util.Set.of("info","authorization","save","disconnect").contains(call.method)) { result.notImplemented(); return; }
            final boolean mutation = call.method.equals("save") || call.method.equals("disconnect");
            final long expected = mutation ? revision.incrementAndGet() : 0;
            executor.execute(() -> {
                try {
                    Object value;
                    switch(call.method) {
                        case "info" -> value=store.info();
                        case "authorization" -> value=store.authorization();
                        case "save" -> {
                            Map<String,Object> arguments=call.arguments();
                            if(arguments==null || !(arguments.get("url") instanceof String)
                                || !(arguments.get("user") instanceof String) || !(arguments.get("password") instanceof String)) throw new IllegalArgumentException();
                            synchronized(mutationLock) {
                                if (expected != revision.get()) throw new IllegalStateException();
                                store.save((String)arguments.get("url"),(String)arguments.get("user"),(String)arguments.get("password"));
                            }
                            value=true;
                        }
                        default -> {
                            synchronized(mutationLock) {
                                if (expected != revision.get()) throw new IllegalStateException();
                                store.disconnect();
                            }
                            value=true;
                        }
                    }
                    main.post(() -> result.success(value));
                } catch(IllegalArgumentException error) { main.post(() -> result.error("invalid_argument","Invalid account configuration",DiagnosticErrorDetails.from(error))); }
                catch(Exception error) { main.post(() -> result.error("unavailable","Account storage unavailable",DiagnosticErrorDetails.from(error))); }
            });
        });
    }
}
