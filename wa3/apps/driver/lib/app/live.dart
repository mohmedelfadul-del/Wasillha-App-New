import 'dart:async';

/// An authoritative realtime read plus whether it came from the local cache
/// (brief rule 3: show "may be out of date" when that persists).
class Live<T> {
  const Live(this.data, {this.fromCache = false});
  final T data;
  final bool fromCache;
}

/// Emits [combine] of the latest values once both streams have emitted.
Stream<R> combineLatest2<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> out;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;
  A? la;
  B? lb;
  var hasA = false, hasB = false;
  void emit() {
    if (hasA && hasB) out.add(combine(la as A, lb as B));
  }

  out = StreamController<R>(
    onListen: () {
      sa = a.listen((v) {
        la = v;
        hasA = true;
        emit();
      }, onError: out.addError);
      sb = b.listen((v) {
        lb = v;
        hasB = true;
        emit();
      }, onError: out.addError);
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
    },
  );
  return out.stream;
}

/// Latest value of every stream in a keyed set that itself changes over time:
/// [keys] emits the current key set, [open] opens one stream per key. Emits
/// the map of latest values once every current key has emitted.
Stream<Map<K, V>> switchCombine<K, V>(Stream<List<K>> keys, Stream<V> Function(K key) open) {
  late StreamController<Map<K, V>> out;
  StreamSubscription<List<K>>? sk;
  final subs = <K, StreamSubscription<V>>{};
  final latest = <K, V>{};
  var current = <K>[];
  void emit() {
    if (current.every(latest.containsKey)) out.add({for (final k in current) k: latest[k] as V});
  }

  out = StreamController<Map<K, V>>(
    onListen: () {
      sk = keys.listen((ks) {
        current = ks;
        for (final k in subs.keys.where((k) => !ks.contains(k)).toList()) {
          subs.remove(k)?.cancel();
          latest.remove(k);
        }
        for (final k in ks) {
          subs.putIfAbsent(k, () => open(k).listen((v) {
                latest[k] = v;
                emit();
              }, onError: out.addError));
        }
        emit();
      }, onError: out.addError);
    },
    onCancel: () async {
      await sk?.cancel();
      for (final s in subs.values) {
        await s.cancel();
      }
    },
  );
  return out.stream;
}
