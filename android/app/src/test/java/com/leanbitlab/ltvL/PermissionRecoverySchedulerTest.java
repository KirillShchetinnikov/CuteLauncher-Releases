package com.leanbitlab.ltvL;

import androidx.work.Configuration;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;
import androidx.work.testing.SynchronousExecutor;
import androidx.work.testing.WorkManagerTestInitHelper;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36}, application = LauncherApplication.class)
public class PermissionRecoverySchedulerTest {
    @Test public void repeatedEntryPointsKeepOnlyOnePeriodicAndOneDelayedCheck() throws Exception {
        var context = RuntimeEnvironment.getApplication();
        WorkManagerTestInitHelper.initializeTestWorkManager(context, new Configuration.Builder()
                .setExecutor(new SynchronousExecutor()).setTaskExecutor(new SynchronousExecutor()).build());
        var scheduled = PermissionRecoveryScheduler.class.getDeclaredField("scheduled");
        scheduled.setAccessible(true); scheduled.setBoolean(null, false);
        PermissionRecoveryScheduler.enqueue(context, 3);
        PermissionRecoveryScheduler.enqueue(context, 3);
        var manager = WorkManager.getInstance(context);
        var periodic = manager.getWorkInfosForUniqueWork("cute-permission-health").get();
        var once = manager.getWorkInfosForUniqueWork("cute-permission-check").get();
        assertEquals(1, periodic.size()); assertEquals(1, once.size());
        assertEquals(WorkInfo.State.ENQUEUED, periodic.get(0).getState());
        assertEquals(WorkInfo.State.ENQUEUED, once.get(0).getState());
        manager.cancelAllWork().getResult().get();
    }
}
