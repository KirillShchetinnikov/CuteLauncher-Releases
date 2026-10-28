package com.leanbitlab.ltvL;

import android.content.Context;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineGroup;
import io.flutter.embedding.engine.dart.DartExecutor;

/** Lazy shared resources, not cached running panels. Retains application context only. */
final class LauncherEngineGroup {
    private static FlutterEngineGroup group;
    static synchronized FlutterEngineGroup get(Context context, String[] vmArgs) {
        if (group == null) group = new FlutterEngineGroup(context.getApplicationContext(), vmArgs);
        return group;
    }
    static FlutterEngine panel(Context context, String entrypoint) {
        FlutterEngineGroup shared = get(context, null);
        String bundle = FlutterInjector.instance().flutterLoader().findAppBundlePath();
        return shared.createAndRunEngine(new FlutterEngineGroup.Options(context.getApplicationContext())
                .setDartEntrypoint(new DartExecutor.DartEntrypoint(bundle, entrypoint)));
    }
}
