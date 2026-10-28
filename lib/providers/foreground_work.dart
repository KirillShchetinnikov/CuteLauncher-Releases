import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../diagnostics/startup_trace.dart';

class _Work {
  final Object owner;
  final Completer<void> done = Completer<void>();
  Future<void> Function() action;
  DateTime after;
  final int priority;
  final Duration delay;
  final DateTime queuedAt;
  bool cancelled = false;
  _Work(this.owner, this.action, this.after, this.priority, this.delay, this.queuedAt);
}

/// Optional refreshes share a bounded queue. UI and time-critical controls never
/// await this queue. A pending request is replaced, rather than multiplied.
class ForegroundWork with WidgetsBindingObserver {
  final DateTime Function() now;
  final int concurrency;
  final _pending = <Object, _Work>{};
  final _running = <Object, _Work>{};
  final _completed = <Object, DateTime>{};
  Timer? _timer, _startupTimeout;
  bool _ready = false, _disposed = false, _foreground = true;
  DateTime? _idleAfter;

  ForegroundWork({DateTime Function()? now, this.concurrency = 2})
      : now = now ?? DateTime.now {
    final binding = WidgetsBinding.instance;
    _foreground = binding.lifecycleState == null || binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    HardwareKeyboard.instance.addHandler(_input);
    // Recovery/empty screens must not leave optional work permanently gated.
    _startupTimeout = Timer(const Duration(seconds: 3), homeReady);
  }

  bool _input(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) deferForInput();
    return false;
  }

  void deferForInput() {
    _idleAfter = now().add(const Duration(milliseconds: 350));
    _pump();
  }

  void homeReady() {
    if (_disposed || _ready) return;
    _ready = true;
    _startupTimeout?.cancel();
    for (final job in _pending.values) {
      final earliest = now().add(job.delay);
      if (job.after.isBefore(earliest)) job.after = earliest;
    }
    _pump();
  }

  Future<void> schedule(Object owner, Future<void> Function() action, {
    Duration delay = const Duration(milliseconds: 350),
    Duration maxAge = Duration.zero, int priority = 0,
  }) {
    if (_disposed) return Future.value();
    final completed = _completed[owner];
    if (completed != null && now().difference(completed) >= Duration.zero &&
        now().difference(completed) < maxAge) { return Future.value(); }
    final pending = _pending[owner];
    if (pending != null) {
      pending.action = action;
      return pending.done.future;
    }
    final work = _Work(owner, action, now().add(delay), priority, delay, now());
    _pending[owner] = work;
    _pump();
    return work.done.future;
  }

  void cancel(Object owner) {
    _running[owner]?.cancelled = true;
    final work = _pending.remove(owner);
    if (work != null) work.done.complete();
    _completed.remove(owner);
  }

  void _pump() {
    _timer?.cancel();
    if (_disposed || !_ready || !_foreground || _running.length >= concurrency || _pending.isEmpty) return;
    if (_idleAfter != null && now().isBefore(_idleAfter!)) {
      final oldest = _pending.values.map((job) => job.queuedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      final deadline = oldest.add(const Duration(seconds: 5));
      if (now().isBefore(deadline)) {
        final next = _idleAfter!.isBefore(deadline) ? _idleAfter! : deadline;
        _timer = Timer(next.difference(now()), _pump);
        return;
      }
    }
    final jobs = _pending.values.toList()..sort((a, b) {
      final order = b.priority.compareTo(a.priority);
      return order != 0 ? order : a.after.compareTo(b.after);
    });
    final eligible = jobs.where((job) => !_running.containsKey(job.owner) && !job.after.isAfter(now()));
    if (eligible.isEmpty) {
      final waiting = jobs.where((job) => !_running.containsKey(job.owner));
      if (waiting.isEmpty) return;
      final next = waiting.map((job) => job.after).reduce((a, b) => a.isBefore(b) ? a : b);
      _timer = Timer(next.difference(now()), _pump);
      return;
    }
    final job = eligible.first;
    _pending.remove(job.owner);
    _running[job.owner] = job;
    final watch = Stopwatch()..start();
    Future<void>.sync(job.action).then((_) {
      if (!_disposed && !job.cancelled) _completed[job.owner] = now();
      job.done.complete();
    }, onError: (Object error, StackTrace stack) {
      job.done.completeError(error, stack);
    }).whenComplete(() {
      _running.remove(job.owner);
      StartupTrace.mark('backgroundWork', {'durationUs': watch.elapsedMicroseconds});
      _pump();
    });
    _pump();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _timer?.cancel();
    } else {
      for (final job in _pending.values) {
        final earliest = now().add(const Duration(milliseconds: 350));
        if (job.after.isBefore(earliest)) job.after = earliest;
      }
      _pump();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _startupTimeout?.cancel();
    for (final job in _pending.values) { job.done.complete(); }
    _pending.clear();
    _completed.clear();
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_input);
  }
}
