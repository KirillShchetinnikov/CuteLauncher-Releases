package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.drawable.Drawable;
import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Reads installed theme resources on the image worker. No pack activity is started. */
final class IconPacks {
    private final PackageManager manager;
    private String activePack;
    private long revision;
    private Set<String> installed = Set.of();
    private Map<ComponentName, String> icons = Map.of();

    IconPacks(PackageManager manager) { this.manager = manager; }

    Map<String, String> available() {
        Map<String, String> result = new HashMap<>();
        for (Intent intent : List.of(new Intent("org.adw.launcher.THEMES"),
                new Intent("com.novalauncher.THEME"),
                new Intent(Intent.ACTION_MAIN).addCategory("com.anddoes.launcher.THEME"))) {
            for (var entry : manager.queryIntentActivities(intent, 0)) {
                var app = entry.activityInfo.applicationInfo;
                result.put(app.packageName, app.loadLabel(manager).toString());
            }
        }
        return result;
    }

    synchronized Drawable icon(String pack, String target) {
        try {
            var info = manager.getPackageInfo(pack, 0);
            Resources resources = manager.getResourcesForApplication(info.applicationInfo);
            if (!pack.equals(activePack) || revision != info.lastUpdateTime || !installed.contains(target)) {
                var packages = new HashSet<String>();
                for (var app : manager.getInstalledApplications(0)) packages.add(app.packageName);
                packages.add(target);
                Map<ComponentName, String> parsed;
                try {
                    parsed = read(resources, pack, packages);
                } catch (IOException | XmlPullParserException | Resources.NotFoundException unavailable) {
                    parsed = Map.of();
                }
                installed = packages;
                icons = parsed;
                activePack = pack;
                revision = info.lastUpdateTime;
            }
            String name = match(manager.getLeanbackLaunchIntentForPackage(target));
            if (name == null) name = match(manager.getLaunchIntentForPackage(target));
            if (name == null) return null;
            int id = resources.getIdentifier(name, "drawable", pack);
            return id == 0 ? null : resources.getDrawable(id, null);
        } catch (PackageManager.NameNotFoundException | RuntimeException unavailable) {
            return null;
        }
    }

    private String match(Intent launch) {
        return launch == null ? null : icons.get(launch.getComponent());
    }

    private static Map<ComponentName, String> read(Resources resources, String pack, Set<String> packages)
            throws IOException, XmlPullParserException {
        int id = resources.getIdentifier("appfilter", "xml", pack);
        if (id != 0) {
            try (var parser = resources.getXml(id)) { return parse(parser, packages); }
        }
        try (InputStream input = resources.getAssets().open("appfilter.xml")) {
            var parser = Xml.newPullParser();
            parser.setInput(input, null);
            return parse(parser, packages);
        }
    }

    static Map<ComponentName, String> parse(XmlPullParser parser, Set<String> packages)
            throws IOException, XmlPullParserException {
        var result = new HashMap<ComponentName, String>();
        for (int count = 0, event = parser.next(); event != XmlPullParser.END_DOCUMENT; event = parser.next()) {
            if (++count > 500000) throw new IOException("Oversized appfilter");
            if (event != XmlPullParser.START_TAG || !"item".equals(parser.getName())) continue;
            String spec = parser.getAttributeValue(null, "component");
            if (spec == null || spec.length() > 1024 || !spec.startsWith("ComponentInfo{") || !spec.endsWith("}")) continue;
            ComponentName component = ComponentName.unflattenFromString(spec.substring(14, spec.length() - 1));
            if (component == null || !packages.contains(component.getPackageName())) continue;
            String name = parser.getAttributeValue(null, "drawable");
            if (name != null && name.length() <= 255 && name.matches("[a-z0-9_]+")) result.put(component, name);
        }
        return result;
    }
}
