import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/cache/cached_resource.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/lessons/data/lesson_repository.dart';
import 'package:streaklearn/features/lessons/domain/lesson.dart';

import '../../../helpers/fake_asset_bundle.dart';
import '../../../helpers/result_helpers.dart';
import '../../../helpers/scripted_random.dart';

const lessonsJson = '''
[
  {
    "id": "lesson-1",
    "title": "Flutter Basics & Widgets",
    "topic": "Fundamentals",
    "thumbnail": "https://example.com/1.png",
    "content": "In Flutter, everything is a widget."
  },
  {
    "id": "lesson-2",
    "title": "Asynchronous Programming in Dart",
    "topic": "Dart",
    "thumbnail": "https://example.com/2.png",
    "content": "Dart uses Futures and Streams."
  }
]
''';

const ttl = Duration(minutes: 5);

(LessonRepository, FakeAssetBundle) buildRepository({
  String? lessonsAsset,
  double failureRate = 0.0,
  Random? random,
  Duration Function()? elapsed,
}) {
  final bundle = FakeAssetBundle({
    if (lessonsAsset != null) ApiClient.lessonsAsset: lessonsAsset,
  });
  final repository = LessonRepository(
    apiClient: ApiClient(
      bundle: bundle,
      random: random,
      failureRate: failureRate,
      latency: Duration.zero,
    ),
    cache: CachedResource(ttl: ttl, elapsed: elapsed),
  );
  return (repository, bundle);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LessonRepository.getLessons', () {
    test('returns Success with typed lessons for a valid payload', () async {
      final (repository, _) = buildRepository(lessonsAsset: lessonsJson);

      final lessons = successValue(await repository.getLessons());

      expect(lessons, hasLength(2));
      expect(lessons.first.id, 'lesson-1');
      expect(lessons.last.topic, 'Dart');
    });

    test('returns NetworkFailure when the simulated network fails', () async {
      final (repository, _) = buildRepository(
        lessonsAsset: lessonsJson,
        failureRate: 1.0,
      );

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<NetworkFailure>());
    });

    test('returns DataParsingFailure for invalid JSON', () async {
      final (repository, _) = buildRepository(lessonsAsset: 'not json at all');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when the payload is not a list', () async {
      final (repository, _) = buildRepository(lessonsAsset: '{"lessons": []}');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when an entry is malformed', () async {
      final (repository, _) = buildRepository(lessonsAsset: '[{"id": 1}]');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns UnexpectedFailure when the asset cannot be loaded', () async {
      final (repository, _) = buildRepository();

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<UnexpectedFailure>());
    });

    test('parses the real bundled lessons asset', () async {
      final repository = LessonRepository(
        apiClient: ApiClient(latency: Duration.zero),
        cache: CachedResource(ttl: ttl),
      );

      final lessons = successValue(await repository.getLessons());

      expect(lessons, hasLength(3));
      expect(
        lessons.map((lesson) => lesson.id),
        containsAll(['lesson-1', 'lesson-2', 'lesson-3']),
      );
    });
  });

  group('LessonRepository caching', () {
    test('serves repeat calls from cache without refetching', () async {
      final (repository, bundle) = buildRepository(lessonsAsset: lessonsJson);

      final first = successValue(await repository.getLessons());
      final second = successValue(await repository.getLessons());

      expect(second, first);
      expect(bundle.loadCounts[ApiClient.lessonsAsset], 1);
    });

    test('returns an unmodifiable list so callers cannot corrupt the cache',
        () async {
      final (repository, _) = buildRepository(lessonsAsset: lessonsJson);

      final lessons = successValue(await repository.getLessons());

      expect(lessons.removeLast, throwsUnsupportedError);
    });

    test('concurrent calls share a single fetch', () async {
      final (repository, bundle) = buildRepository(lessonsAsset: lessonsJson);

      final results = await Future.wait([
        repository.getLessons(),
        repository.getLessons(),
      ]);

      expect(results, everyElement(isA<Success<List<Lesson>>>()));
      expect(bundle.loadCounts[ApiClient.lessonsAsset], 1);
    });

    test('forceRefresh bypasses the cache and refetches', () async {
      final (repository, bundle) = buildRepository(lessonsAsset: lessonsJson);

      await repository.getLessons();
      final refreshed = await repository.getLessons(forceRefresh: true);

      expect(refreshed, isA<Success<List<Lesson>>>());
      expect(bundle.loadCounts[ApiClient.lessonsAsset], 2);
    });

    test('refetches once the cache entry expires', () async {
      var elapsed = Duration.zero;
      final (repository, bundle) = buildRepository(
        lessonsAsset: lessonsJson,
        elapsed: () => elapsed,
      );

      await repository.getLessons();
      elapsed = ttl;
      await repository.getLessons();

      expect(bundle.loadCounts[ApiClient.lessonsAsset], 2);
    });

    test('does not cache failures', () async {
      final (repository, bundle) = buildRepository(
        lessonsAsset: lessonsJson,
        failureRate: 0.5,
        random: ScriptedRandom([0.0, 0.9]),
      );

      expect(failureOf(await repository.getLessons()), isA<NetworkFailure>());
      expect(successValue(await repository.getLessons()), hasLength(2));
      expect(bundle.loadCounts[ApiClient.lessonsAsset], 1);
    });

    test('keeps the cached list when a forced refresh fails', () async {
      final (repository, bundle) = buildRepository(
        lessonsAsset: lessonsJson,
        failureRate: 0.5,
        random: ScriptedRandom([0.9, 0.0]),
      );

      final first = successValue(await repository.getLessons());
      expect(
        failureOf(await repository.getLessons(forceRefresh: true)),
        isA<NetworkFailure>(),
      );
      final third = successValue(await repository.getLessons());

      expect(third, first);
      expect(bundle.loadCounts[ApiClient.lessonsAsset], 1);
    });
  });
}
