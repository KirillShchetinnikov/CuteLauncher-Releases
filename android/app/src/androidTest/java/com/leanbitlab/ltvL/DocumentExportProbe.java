package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import java.util.List;

/** Regression for OEM stubs and the URI grant needed by file manager Save activities. */
public final class DocumentExportProbe extends Instrumentation {
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }
    private ResolveInfo target(String pkg, String name, boolean exported) {
        ResolveInfo info = new ResolveInfo();
        info.activityInfo = new ActivityInfo();
        info.activityInfo.packageName = pkg;
        info.activityInfo.name = name;
        info.activityInfo.enabled = true;
        info.activityInfo.exported = exported;
        return info;
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            String packageName = getTargetContext().getPackageName();
            var pm = getTargetContext().getPackageManager();
            var reports = pm.resolveContentProvider(packageName + ".reports", 0);
            var updates = pm.resolveContentProvider(packageName + ".updates", 0);
            if (reports == null || updates == null || reports.name.equals(updates.name))
                throw new AssertionError("Report and update providers need distinct registered identities");
            ResolveInfo stub = target("com.android.tv.frameworkpackagestubs", "Stubs$DocumentsStub", true);
            ResolveInfo real = target("io.cutelauncher.fixture.documents", "CreateDocument", true);
            ResolveInfo hidden = target("private.handler", "Hidden", false);
            Intent create = new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json");
            if (DocumentFiles.compatibleIntent(create, List.of(stub, hidden)) != null)
                throw new AssertionError("Stub/private activities must not count as a picker");
            Intent selected = DocumentFiles.compatibleIntent(create, List.of(stub, real));
            if (!real.activityInfo.packageName.equals(selected.getComponent().getPackageName()))
                throw new AssertionError("Genuine picker must be preferred");
            Intent send = new Intent(Intent.ACTION_SEND).setType("application/json")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            ResolveInfo manager = target("com.alphainventor.filemanager", "SaveToActivity", true);
            selected = DocumentFiles.compatibleIntent(send, List.of(stub, manager));
            if (!Intent.ACTION_SEND.equals(selected.getAction())
                || (selected.getFlags() & Intent.FLAG_GRANT_READ_URI_PERMISSION) == 0
                || !manager.activityInfo.packageName.equals(selected.getComponent().getPackageName()))
                throw new AssertionError("File manager must receive SEND and the read grant");
            selected = DocumentFiles.compatibleIntent(send, List.of(manager, real, stub));
            if (!Intent.ACTION_CHOOSER.equals(selected.getAction())) throw new AssertionError("Multiple genuine handlers need a chooser");
            Intent[] additional = selected.getParcelableArrayExtra(Intent.EXTRA_INITIAL_INTENTS, Intent.class);
            if (additional == null || additional.length != 1) throw new AssertionError("Chooser must exclude stub");
            report.putString("result", "PASS: stub rejection, genuine picker, SEND grant and filtered chooser");
            finish(-1, report);
        } catch (Throwable error) { report.putString("result", "FAIL: " + error); finish(0, report); }
    }
}
