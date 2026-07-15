import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/cache/cached_resource.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/quiz/data/quiz_repository.dart';

import '../../../helpers/fake_asset_bundle.dart';
import '../../../helpers/result_helpers.dart';
import '../../../helpers/scripted_random.dart';

const quizzesJson = '''
[
  {
    "lessonId": "lesson-1",
    "questions": [
      {
        "id": "q1",
        "question": "What is the core building block of a Flutter UI?",
        "options": ["Widget", "Activity", "Component", "View"],
        "correctIndex": 0
      }
    ]
  },
  {
    "lessonId": "lesson-2",
    "questions": [
      {
        "id": "q3",
        "question": "Which keyword pauses execution until a Future completes?",
        "options": ["await", "defer", "wait"],
        "correctIndex": 0
      }
    ]
  }
]
''';

const ttl = Duration(minutes: 5);

(QuizRepository, FakeAssetBundle) buildRepository({
  String? quizzesAsset,
  double failureRate = 0.0,
  Random? random,
  Duration Function()? elapsed,
}) {
  final bundle = FakeAssetBundle({
    if (quizzesAsset != null) ApiClient.quizzesAsset: quizzesAsset,
  });
  final repository = QuizRepository(
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

  group('QuizRepository.getQuizByLessonId', () {
    test('returns Success with the quiz matching the lesson id', () async {
      final (repository, _) = buildRepository(quizzesAsset: quizzesJson);

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-2'),
      );

      expect(quiz?.lessonId, 'lesson-2');
      expect(quiz?.questions.first.id, 'q3');
    });

    test('returns Success(null) when the lesson has no quiz', () async {
      final (repository, _) = buildRepository(quizzesAsset: quizzesJson);

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-999'),
      );

      expect(quiz, isNull);
    });

    test('returns NetworkFailure when the simulated network fails', () async {
      final (repository, _) = buildRepository(
        quizzesAsset: quizzesJson,
        failureRate: 1.0,
      );

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('returns DataParsingFailure for invalid JSON', () async {
      final (repository, _) = buildRepository(quizzesAsset: '{oops');

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when a quiz entry is malformed', () async {
      final (repository, _) = buildRepository(
        quizzesAsset: '[{"lessonId": 1}]',
      );

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns UnexpectedFailure when the asset cannot be loaded', () async {
      final (repository, _) = buildRepository();

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<UnexpectedFailure>());
    });

    test('picks the first quiz when the payload duplicates a lesson id',
        () async {
      const duplicated = '''
      [
        {
          "lessonId": "lesson-1",
          "questions": [
            {"id": "q1", "question": "First?", "options": ["a"], "correctIndex": 0}
          ]
        },
        {
          "lessonId": "lesson-1",
          "questions": [
            {"id": "q2", "question": "Second?", "options": ["b"], "correctIndex": 0}
          ]
        }
      ]
      ''';
      final (repository, _) = buildRepository(quizzesAsset: duplicated);

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(quiz?.questions.first.id, 'q1');
    });

    test('finds a quiz in the real bundled asset', () async {
      final repository = QuizRepository(
        apiClient: ApiClient(latency: Duration.zero),
        cache: CachedResource(ttl: ttl),
      );

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(quiz?.questions, hasLength(2));
    });

    test('returns Success(null) for lesson-3 in the real bundled asset',
        () async {
      final repository = QuizRepository(
        apiClient: ApiClient(latency: Duration.zero),
        cache: CachedResource(ttl: ttl),
      );

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-3'),
      );

      expect(quiz, isNull);
    });
  });

  group('QuizRepository caching', () {
    test('returns to a visited lesson without refetching', () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      final first = successValue(
        await repository.getQuizByLessonId('lesson-1'),
      );
      final second = successValue(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(second, first);
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });

    test('caches the no-quiz answer as well', () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      expect(
        successValue(await repository.getQuizByLessonId('lesson-999')),
        isNull,
      );
      expect(
        successValue(await repository.getQuizByLessonId('lesson-999')),
        isNull,
      );
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });

    test('a single fetch serves every lesson in the payload', () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      await repository.getQuizByLessonId('lesson-1');
      final second = successValue(
        await repository.getQuizByLessonId('lesson-2'),
      );

      expect(second?.lessonId, 'lesson-2');
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });

    test('concurrent lookups for the same lesson share a single fetch',
        () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      final results = await Future.wait([
        repository.getQuizByLessonId('lesson-1'),
        repository.getQuizByLessonId('lesson-1'),
      ]);

      expect(results, hasLength(2));
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });

    test('concurrent lookups for different lessons share a single fetch',
        () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      final results = await Future.wait([
        repository.getQuizByLessonId('lesson-1'),
        repository.getQuizByLessonId('lesson-2'),
      ]);

      final quizzes = results.map(successValue).toList();
      expect(quizzes.first?.lessonId, 'lesson-1');
      expect(quizzes.last?.lessonId, 'lesson-2');
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });

    test('forceRefresh bypasses the cache and refetches', () async {
      final (repository, bundle) = buildRepository(quizzesAsset: quizzesJson);

      await repository.getQuizByLessonId('lesson-1');
      await repository.getQuizByLessonId('lesson-1', forceRefresh: true);

      expect(bundle.loadCounts[ApiClient.quizzesAsset], 2);
    });

    test('does not cache failures', () async {
      final (repository, bundle) = buildRepository(
        quizzesAsset: quizzesJson,
        failureRate: 0.5,
        random: ScriptedRandom([0.0, 0.9]),
      );

      expect(
        failureOf(await repository.getQuizByLessonId('lesson-1')),
        isA<NetworkFailure>(),
      );
      final retried = successValue(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(retried?.lessonId, 'lesson-1');
      expect(bundle.loadCounts[ApiClient.quizzesAsset], 1);
    });
  });
}
