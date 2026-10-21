package com.leanbitlab.ltvL;

import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public final class ApplicationLoaderTest {
    public static void main(String[] args) throws Exception {
        ExecutorService worker = Executors.newSingleThreadExecutor();
        ExecutorService callbacks = Executors.newSingleThreadExecutor();
        CountDownLatch release = new CountDownLatch(1);
        CountDownLatch started = new CountDownLatch(1);
        CountDownLatch finished = new CountDownLatch(4);
        AtomicInteger successes = new AtomicInteger();
        AtomicInteger failures = new AtomicInteger();
        Thread caller = Thread.currentThread();
        try {
            ApplicationLoader.load(worker, callbacks, () -> {
                if (Thread.currentThread() == caller) throw new AssertionError("Query blocks caller");
                started.countDown();
                release.await();
                return "ok";
            }, value -> { successes.incrementAndGet(); finished.countDown(); },
               error -> { failures.incrementAndGet(); finished.countDown(); });
            if (!started.await(2, TimeUnit.SECONDS)) throw new AssertionError("Worker not started");
            // Reaching here while query is blocked proves the caller is free.
            release.countDown();
            ApplicationLoader.load(worker, callbacks, () -> { throw new SecurityException(); },
                value -> { successes.incrementAndGet(); finished.countDown(); },
                error -> { failures.incrementAndGet(); finished.countDown(); });
            ApplicationLoader.load(worker, callbacks, () -> null,
                value -> { successes.incrementAndGet(); finished.countDown(); },
                error -> { failures.incrementAndGet(); finished.countDown(); });
            ApplicationLoader.load(task -> { throw new RejectedExecutionException(); }, callbacks, () -> "bad",
                value -> { successes.incrementAndGet(); finished.countDown(); },
                error -> { failures.incrementAndGet(); finished.countDown(); });
            if (!finished.await(3, TimeUnit.SECONDS) || successes.get() != 1 || failures.get() != 3)
                throw new AssertionError("Incorrect completion results");
            System.out.println("ApplicationLoader checks passed");
        } finally { release.countDown(); worker.shutdownNow(); callbacks.shutdownNow(); }
    }
}
