/// A value read from a realtime listener, with whether it came from the local
/// cache (possibly out of date) rather than the server.
class Live<T> {
  const Live(this.value, {this.fromCache = false});
  final T value;
  final bool fromCache;
}
