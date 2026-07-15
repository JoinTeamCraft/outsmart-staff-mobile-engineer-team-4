import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/cache/cached_resource.dart';
import 'package:streaklearn/core/result/result.dart';

import '../../helpers/result_helpers.dart';

void main() {
  group('CachedResource', () {
    test('caches a successful fetch', () async {
      final resource = CachedResource<int>(ttl: const Duration(minutes: 5));
      var fetches = 0;
      Future<Result<int>> fetch() async => Success(++fetches);

      expect(successValue(await resource.get(fetch)), 1);
      expect(successValue(await resource.get(fetch)), 1);
      expect(fetches, 1);
    });

    test('does not cache failures', () async {
      final resource = CachedResource<int>(ttl: const Duration(minutes: 5));
      var calls = 0;
      Future<Result<int>> fetch() async {
        calls++;
        return calls == 1 ? const Failure(NetworkFailure()) : Success(calls);
      }

      expect(failureOf(await resource.get(fetch)), isA<NetworkFailure>());
      expect(successValue(await resource.get(fetch)), 2);
    });

    test('expires the entry once the ttl elapses', () async {
      var elapsed = Duration.zero;
      final resource = CachedResource<int>(
        ttl: const Duration(minutes: 5),
        elapsed: () => elapsed,
      );
      var fetches = 0;
      Future<Result<int>> fetch() async => Success(++fetches);

      await resource.get(fetch);
      elapsed = const Duration(minutes: 4, seconds: 59);
      expect(successValue(await resource.get(fetch)), 1);

      elapsed = const Duration(minutes: 5);
      expect(successValue(await resource.get(fetch)), 2);
    });

    test('concurrent callers join a single fetch', () async {
      final resource = CachedResource<int>(ttl: const Duration(minutes: 5));
      var fetches = 0;
      Future<Result<int>> fetch() async {
        fetches++;
        await Future<void>.delayed(Duration.zero);
        return Success(fetches);
      }

      final results = await Future.wait([
        resource.get(fetch),
        resource.get(fetch),
      ]);

      expect(results.map(successValue), everyElement(1));
      expect(fetches, 1);
    });

    test('forceRefresh skips the cache read but joins an in-flight fetch',
        () async {
      final resource = CachedResource<int>(ttl: const Duration(minutes: 5));
      var fetches = 0;
      Future<Result<int>> fetch() async {
        fetches++;
        await Future<void>.delayed(Duration.zero);
        return Success(fetches);
      }

      await resource.get(fetch);
      expect(successValue(await resource.get(fetch, forceRefresh: true)), 2);

      final joined = await Future.wait([
        resource.get(fetch, forceRefresh: true),
        resource.get(fetch, forceRefresh: true),
      ]);
      expect(joined.map(successValue), everyElement(3));
      expect(fetches, 3);
    });

    test('a failed refresh keeps the previous entry', () async {
      final resource = CachedResource<int>(ttl: const Duration(minutes: 5));
      var calls = 0;
      Future<Result<int>> fetch() async {
        calls++;
        return calls == 2 ? const Failure(NetworkFailure()) : Success(calls);
      }

      expect(successValue(await resource.get(fetch)), 1);
      expect(
        failureOf(await resource.get(fetch, forceRefresh: true)),
        isA<NetworkFailure>(),
      );
      expect(successValue(await resource.get(fetch)), 1);
    });
  });
}
