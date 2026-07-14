import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/quiz/data/quiz_repository.dart';

import '../../../helpers/fake_asset_bundle.dart';
import '../../../helpers/result_helpers.dart';

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

QuizRepository buildRepository({
  String? quizzesAsset,
  double failureRate = 0.0,
}) =>
    QuizRepository(
      apiClient: ApiClient(
        bundle: FakeAssetBundle({
          if (quizzesAsset != null) ApiClient.quizzesAsset: quizzesAsset,
        }),
        failureRate: failureRate,
        latency: Duration.zero,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizRepository.getQuizByLessonId', () {
    test('returns Success with the quiz matching the lesson id', () async {
      final repository = buildRepository(quizzesAsset: quizzesJson);

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-2'),
      );

      expect(quiz?.lessonId, 'lesson-2');
      expect(quiz?.questions.first.id, 'q3');
    });

    test('returns Success(null) when the lesson has no quiz', () async {
      final repository = buildRepository(quizzesAsset: quizzesJson);

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-999'),
      );

      expect(quiz, isNull);
    });

    test('returns NetworkFailure when the simulated network fails', () async {
      final repository = buildRepository(
        quizzesAsset: quizzesJson,
        failureRate: 1.0,
      );

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('returns DataParsingFailure for invalid JSON', () async {
      final repository = buildRepository(quizzesAsset: '{oops');

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when a quiz entry is malformed', () async {
      final repository = buildRepository(quizzesAsset: '[{"lessonId": 1}]');

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns UnexpectedFailure when the asset cannot be loaded', () async {
      final repository = buildRepository();

      final failure = failureOf(
        await repository.getQuizByLessonId('lesson-1'),
      );

      expect(failure, isA<UnexpectedFailure>());
    });

    test('finds a quiz in the real bundled asset', () async {
      final repository = QuizRepository(
        apiClient: ApiClient(latency: Duration.zero),
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
      );

      final quiz = successValue(
        await repository.getQuizByLessonId('lesson-3'),
      );

      expect(quiz, isNull);
    });
  });
}
