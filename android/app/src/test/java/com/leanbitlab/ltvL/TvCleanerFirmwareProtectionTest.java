package com.leanbitlab.ltvL;
import java.util.*;
import org.json.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class TvCleanerFirmwareProtectionTest {
    @Test public void exactModelAndFirmwareAreRequiredAndMalformedRulesFailClosed() throws Exception {
        var identity = new LinkedHashMap<>(Map.of("manufacturer", "TCL", "model", "Smart TV Pro",
                "device", "G08", "fingerprint", "TCL/G08_4K_GB/G08:14/UTT2.250416.001/AU02:user/release-keys"));
        var rule = new JSONObject().put("identity", new JSONObject(identity))
                .put("protectedPackages", new JSONArray(List.of("com.tcl.ttvs", "com.tcl.interactive")));
        var catalog = new JSONObject().put("schemaVersion", 1).put("rules", new JSONArray().put(rule));
        assertEquals(Set.of("com.tcl.ttvs", "com.tcl.interactive"),
                TvCleanerFirmwareProtection.protectedPackages(catalog, identity));
        for (String key : identity.keySet()) {
            var changed = new HashMap<>(identity); changed.put(key, identity.get(key) + "-other");
            assertTrue(TvCleanerFirmwareProtection.protectedPackages(catalog, changed).isEmpty());
            changed.remove(key);
            assertTrue(TvCleanerFirmwareProtection.protectedPackages(catalog, changed).isEmpty());
        }
        rule.getJSONObject("identity").remove("fingerprint");
        try { TvCleanerFirmwareProtection.protectedPackages(catalog, identity); fail("Broad rule accepted"); }
        catch (IllegalStateException expected) { }
    }
}
