package com.leanbitlab.ltvL;
import android.content.Context;
import android.content.pm.PackageManager;
import java.util.*;

final class AdbHomeDependencies {
    // The TV removes user names before transport and before diagnostic logging.
    static final String USER_IDS = "pm list users | sed -n 's/.*UserInfo{\\([0-9][0-9]*\\):.*/\\1/p'";
    @SuppressWarnings("deprecation")
    static String blocked(Context context, Map<String, Integer> desired, AdbBridge.Shell shell) {
        var pm = context.getPackageManager();
        return HomeDependencyPolicy.blocked(desired, new HomeDependencyPolicy.Reader() {
            public HomeDependencyPolicy.App app(String name) throws Exception {
                final android.content.pm.PackageInfo info;
                try { info = pm.getPackageInfo(name, PackageManager.GET_PROVIDERS | PackageManager.GET_RECEIVERS
                            | PackageManager.MATCH_DISABLED_COMPONENTS); }
                catch (PackageManager.NameNotFoundException absent) { return null; }
                if (info.applicationInfo == null) throw new IllegalStateException("Missing application metadata");
                var providers = new ArrayList<String>(); var receivers = new ArrayList<String>();
                if (info.providers != null) for (var provider : info.providers) providers.add(provider.name);
                if (info.receivers != null) for (var receiver : info.receivers) receivers.add(receiver.name);
                int mode = pm.getApplicationEnabledSetting(name);
                boolean enabled = mode == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                        mode == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && info.applicationInfo.enabled;
                return new HomeDependencyPolicy.App(enabled, providers, receivers);
            }
            public String userIds() throws Exception { return shell.execute(USER_IDS); }
        });
    }
}
