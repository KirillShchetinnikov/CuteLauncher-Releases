package com.leanbitlab.ltvL;

import java.util.List;
import java.util.concurrent.Executor;
import java.util.function.Consumer;

/** One worker query per foreground entry; state and delivery belong to the callback thread. */
final class ApplicationChanges {
    record Snapshot(int sequence, List<String> packages) {}
    interface Query { Snapshot read(int since) throws Exception; }
    private final Query query;
    private final Executor worker, callbacks;
    private Consumer<List<String>> listener;
    private boolean foreground, running;
    private int sequence;
    private volatile int generation;

    ApplicationChanges(Query query, Executor worker, Executor callbacks) {
        this.query = query; this.worker = worker; this.callbacks = callbacks;
    }

    void listen(Consumer<List<String>> listener) {
        this.listener = listener;
        generation++;
        check();
    }

    void cancel() { listener = null; generation++; }

    void foreground(boolean value) {
        if (foreground == value) return;
        foreground = value;
        generation++;
        if (value) check();
    }

    private void check() {
        if (!foreground || listener == null || running) return;
        final int expected = generation, since = sequence;
        running = true;
        try {
            worker.execute(() -> {
                Snapshot result = null;
                try { if (expected == generation) result = query.read(since); }
                catch (Exception ignored) { /* Preserve the cursor; retry on the next foreground entry. */ }
                final Snapshot snapshot = result;
                callbacks.execute(() -> complete(expected, snapshot));
            });
        } catch (RuntimeException ignored) { running = false; }
    }

    private void complete(int expected, Snapshot snapshot) {
        running = false;
        if (expected != generation) {
            check(); // A pause/resume or new subscription superseded this read.
            return;
        }
        if (!foreground || listener == null || snapshot == null) return;
        if (snapshot.sequence() < sequence) return;
        if (!snapshot.packages().isEmpty()) listener.accept(snapshot.packages());
        sequence = snapshot.sequence();
    }
}
