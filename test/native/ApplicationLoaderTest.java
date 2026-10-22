package com.leanbitlab.ltvL;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public final class ApplicationLoaderTest {
    public static void main(String[] args) throws Exception {
        var worker = Executors.newSingleThreadExecutor();
        var callbacks = new LinkedBlockingQueue<Runnable>();
        var entered = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        var replies = new AtomicInteger();
        var caller = Thread.currentThread();
        try {
            ApplicationLoader.load(worker, callbacks::add, () -> {
                if (Thread.currentThread() == caller) throw new AssertionError("Query on input thread");
                entered.countDown();
                if (!release.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("Timed out");
                return 42L;
            }, value -> {
                if (Thread.currentThread() != caller || value != 42L) throw new AssertionError("Bad result");
                replies.incrementAndGet();
            }, error -> { throw new AssertionError(error); });
            if (!entered.await(5, TimeUnit.SECONDS)) throw new AssertionError("Query not started");
            // Simulate another input on the callback/UI queue while the query is blocked.
            var input = new AtomicInteger();
            callbacks.add(input::incrementAndGet);
            runNext(callbacks);
            if (input.get() != 1 || replies.get() != 0) throw new AssertionError("Input blocked by query");
            release.countDown();
            runNext(callbacks);
            if (replies.get() != 1) throw new AssertionError("Missing result");

            ApplicationLoader.load(worker, callbacks::add, () -> { throw new SecurityException("denied"); },
                value -> { throw new AssertionError("Unexpected success"); },
                error -> {
                    if (!(error instanceof SecurityException) || Thread.currentThread() != caller)
                        throw new AssertionError("Lost failure or wrong callback thread");
                    replies.incrementAndGet();
                });
            runNext(callbacks);
            ApplicationLoader.load(worker, callbacks::add, () -> -1L,
                value -> {
                    if (value != -1L) throw new AssertionError("Permission sentinel changed");
                    replies.incrementAndGet();
                }, error -> { throw new AssertionError(error); });
            runNext(callbacks);
            if (replies.get() != 3 || !callbacks.isEmpty()) throw new AssertionError("Duplicate replies");
            System.out.println("ApplicationLoaderTest passed: input stays available; results and failures use callback thread");
        } finally {
            release.countDown();
            worker.shutdownNow();
        }
    }

    private static void runNext(LinkedBlockingQueue<Runnable> queue) throws Exception {
        var task = queue.poll(5, TimeUnit.SECONDS);
        if (task == null) throw new AssertionError("Missing callback");
        task.run();
    }
}
