import '../result/result.dart';

/// Caches a successful fetch for [ttl] and shares one in-flight fetch among
/// concurrent callers. Freshness comes from a monotonic [Stopwatch].
class CachedResource<T> {
  CachedResource({required this.ttl, Duration Function()? elapsed})
      : _elapsed = elapsed ?? _stopwatchElapsed();

  static Duration Function() _stopwatchElapsed() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  final Duration ttl;
  final Duration Function() _elapsed;
  ({T value, Duration storedAt})? _entry;
  Future<Result<T>>? _inFlight;

  /// Serves the fresh cached value, joins any in-flight fetch, or runs
  /// [fetch]. [forceRefresh] skips the cache read; failures are never cached.
  Future<Result<T>> get(
    Future<Result<T>> Function() fetch, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      if (_entry case (:final value, :final storedAt)
          when _elapsed() - storedAt < ttl) {
        return Future.value(Success(value));
      }
    }
    if (_inFlight case final inFlight?) {
      return inFlight;
    }

    final request = fetch().then((result) {
      if (result case Success(:final value)) {
        _entry = (value: value, storedAt: _elapsed());
      }
      return result;
    }).whenComplete(() => _inFlight = null);
    _inFlight = request;
    return request;
  }
}
