package io.cutelauncher.fixture.recents;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
/** Isolated TV task for automatic recents integration checks. */
public class RecentTasksFixture extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        TextView text = new TextView(this); text.setText("CuteLauncher recent tasks fixture"); setContentView(text);
    }
}
