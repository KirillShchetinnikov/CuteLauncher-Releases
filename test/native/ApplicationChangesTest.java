package com.leanbitlab.ltvL;

import java.util.*;

public final class ApplicationChangesTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static final class Fixture {
        final Queue<Runnable> worker = new ArrayDeque<>(), callbacks = new ArrayDeque<>();
        final List<Integer> queries = new ArrayList<>();
        final List<List<String>> delivered = new ArrayList<>();
        ApplicationChanges.Snapshot result = new ApplicationChanges.Snapshot(0, List.of());
        boolean fail;
        final ApplicationChanges tracker = new ApplicationChanges(since -> {
            queries.add(since);
            if (fail) throw new SecurityException("OEM query denied");
            return result;
        }, worker::add, callbacks::add);
        void finish() { worker.remove().run(); callbacks.remove().run(); }
        void start() { tracker.listen(delivered::add); tracker.foreground(true); finish(); }
        void resume() { tracker.foreground(false); tracker.foreground(true); }
    }
    public static void main(String[] args) {
        Fixture f = new Fixture();
        f.start();
        check(f.delivered.isEmpty() && f.queries.equals(List.of(0)));
        f.tracker.foreground(true);
        check(f.worker.isEmpty()); // Repeated resumed notifications are not an extra entry.
        f.result = new ApplicationChanges.Snapshot(7, List.of("org.example.new", "org.example.removed"));
        f.resume();
        check(f.queries.size() == 1 && f.delivered.isEmpty()); // Query did not run on the caller/UI.
        f.worker.remove().run();
        check(f.delivered.isEmpty()); // Result waits for the callback/UI queue.
        f.callbacks.remove().run();
        check(f.delivered.equals(List.of(f.result.packages())));
        f.result = new ApplicationChanges.Snapshot(7, List.of());
        f.resume(); f.finish();
        check(f.delivered.size() == 1 && f.queries.equals(List.of(0, 0, 7)));

        // A result that arrived after pause is neither delivered nor acknowledged.
        f.result = new ApplicationChanges.Snapshot(8, List.of("org.example.updated"));
        f.resume(); f.worker.remove().run(); f.tracker.foreground(false);
        f.callbacks.remove().run();
        check(f.delivered.size() == 1 && f.worker.isEmpty());
        f.tracker.foreground(true); f.finish();
        check(f.queries.get(f.queries.size() - 1) == 7 && f.delivered.size() == 2);

        // Multiple resumes during a slow read coalesce into one current follow-up.
        f.resume(); f.resume(); f.resume();
        check(f.worker.size() == 1);
        f.finish();
        check(f.worker.size() == 1 && f.delivered.size() == 2);
        f.result = new ApplicationChanges.Snapshot(8, List.of());
        f.finish(); check(f.worker.isEmpty());

        // A failed query leaves the sequence unchanged, with no immediate retry loop.
        f.fail = true; f.resume(); f.finish();
        check(f.worker.isEmpty() && f.delivered.size() == 2);
        f.fail = false; f.result = new ApplicationChanges.Snapshot(9, List.of("org.example.retry"));
        f.resume(); f.finish();
        check(f.queries.get(f.queries.size() - 1) == 8 && f.delivered.size() == 3);

        // Cancel/engine cleanup invalidates queued work and releases the sink.
        f.resume(); f.tracker.cancel(); f.finish();
        check(f.worker.isEmpty() && f.delivered.size() == 3);
        f.resume(); check(f.worker.isEmpty());
        f.result = new ApplicationChanges.Snapshot(10, List.of("org.example.afterSubscription"));
        f.tracker.listen(f.delivered::add); f.finish();
        check(f.queries.get(f.queries.size() - 1) == 9 && f.delivered.size() == 4);
        System.out.println("ApplicationChangesTest passed");
    }
}
