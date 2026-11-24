import 'dart:async';
import 'dart:typed_data';

typedef PosterPriority = int Function();

/// Collects demand for a shared request. Negative means the card moved on.
class PosterDemand {
  final _priorities = <PosterPriority?>[];

  void add(PosterPriority? priority) => _priorities.add(priority);

  int get priority {
    var best = -1;
    _priorities.removeWhere((priority) {
      final value = priority?.call() ?? 0;
      if (value > best) best = value;
      return value < 0;
    });
    return best;
  }
}

typedef _QueuedPoster = ({
  PosterDemand demand,
  Future<Uint8List?> Function() load,
  Completer<Uint8List?> result,
});

/// The order is evaluated when a slot opens so focus changes can promote work
/// that was queued by an adjacent card.
class PosterQueue {
  final _waiting = <_QueuedPoster>[];
  int _running = 0;
  bool _scheduled = false;
  bool _closed = false;

  Future<Uint8List?> load(
    PosterDemand demand,
    Future<Uint8List?> Function() load,
  ) {
    if (_closed) return Future.value();
    final result = Completer<Uint8List?>();
    _waiting.add((demand: demand, load: load, result: result));
    _schedule();
    return result.future;
  }

  void _schedule() {
    if (_scheduled || _closed) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      while (!_closed && _running < 2 && _waiting.isNotEmpty) {
        var highest = -1;
        _QueuedPoster? next;
        _waiting.removeWhere((entry) {
          final priority = entry.demand.priority;
          if (priority < 0) {
            entry.result.complete(null);
            return true;
          }
          if (priority > highest) {
            highest = priority;
            next = entry;
          }
          return false;
        });
        final entry = next;
        if (entry == null) break;
        _waiting.remove(entry);
        _running++;
        entry.result.complete(Future.sync(entry.load).whenComplete(() {
          _running--;
          _schedule();
        }));
      }
    });
  }

  void close() {
    _closed = true;
    for (final entry in _waiting) {
      entry.result.complete(null);
    }
    _waiting.clear();
  }
}
