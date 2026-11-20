/// A realtime read plus whether it came from the local cache
/// (`snapshot.metadata.isFromCache`), so screens can say "may be out of date".
class Live<T> {
  const Live(this.value, {this.fromCache = false});
  final T value;
  final bool fromCache;
  Live<R> map<R>(R Function(T) f) => Live(f(value), fromCache: fromCache);
}
