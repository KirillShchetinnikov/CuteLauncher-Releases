package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class WeatherReceiverTest {
    @Test public void malformedUpdatePreservesLastGoodCacheAndDoesNotNotify() {
        Context context = RuntimeEnvironment.getApplication();
        var prefs = context.getSharedPreferences(WeatherReceiver.PREFS_NAME, 0);
        var events = new ArrayList<String>();
        WeatherReceiver.setListener(events::add);
        var receiver = new WeatherReceiver();
        String good = "{\"location\":\"Town\",\"currentTemp\":\"290\",\"forecasts\":[{\"minTemp\":280}]}";
        try {
            for (String action : List.of(WeatherReceiver.ACTION_GENERIC_WEATHER,
                    WeatherReceiver.ACTION_BREEZY_UPDATE_NOTIFIER,
                    WeatherReceiver.ACTION_BREEZY_UPDATE_NOTIFIER_DEBUG)) {
                receiver.onReceive(context, new Intent(action).putExtra("WeatherJson", good));
                events.clear();
                for (String invalid : List.of("{", "[]", "null", "{} garbage",
                        "{\"timestamp\":\"yesterday\"}", "{\"timestamp\":9223372036854775807}",
                        "{\"utcOffsetSeconds\":9223372036854775807}",
                        "{\"location\":[]}", "{\"currentHumidity\":12.5}",
                        "{\"forecasts\":{}}", "{\"forecasts\":[{\"conditionCode\":\"rain\"}]}")) {
                    receiver.onReceive(context, new Intent(action).putExtra("WeatherJson", invalid));
                    assertEquals(invalid, good, prefs.getString(WeatherReceiver.KEY_WEATHER_JSON, null));
                    assertTrue(invalid, events.isEmpty());
                }
            }
            // A fresh receiver still reads the last valid value when Breezy only signals an update.
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_BREEZY_UPDATE_NOTIFIER));
            assertEquals(List.of(good), events);
        } finally { WeatherReceiver.setListener(null); }
    }

    @Test public void partialNullAndForwardCompatiblePayloadsRemainAccepted() {
        Context context = RuntimeEnvironment.getApplication();
        var prefs = context.getSharedPreferences(WeatherReceiver.PREFS_NAME, 0);
        for (String valid : List.of("{}", "{\"location\":null,\"timestamp\":null}",
                "{\"currentTemp\":\"291.2\",\"unknownField\":{\"future\":true}}",
                "{\"forecasts\":[null,1,{\"humidity\":null,\"date\":42,\"minTemp\":\"280\"}]}")) {
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", valid));
            assertEquals(valid, prefs.getString(WeatherReceiver.KEY_WEATHER_JSON, null));
        }
    }
}
