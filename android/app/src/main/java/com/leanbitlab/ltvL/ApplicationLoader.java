package com.leanbitlab.ltvL;

import java.util.concurrent.Callable;
import java.util.concurrent.Executor;

/** Runs package queries off the platform thread and reports failures without partial results. */
final class ApplicationLoader {
    interface Completion<T> { void accept(T value); }
    static <T> void load(Executor worker, Executor callbacks, Callable<T> query,
                        Completion<T> success, Completion<Exception> failure) {
        try {
            worker.execute(() -> {
                final T value;
                try {
                    value = query.call();
                    if (value == null) throw new IllegalStateException("Missing applications result");
                } catch (Exception error) {
                    callbacks.execute(() -> failure.accept(error));
                    return;
                }
                callbacks.execute(() -> success.accept(value));
            });
        } catch (Exception error) {
            callbacks.execute(() -> failure.accept(error));
        }
    }
}
