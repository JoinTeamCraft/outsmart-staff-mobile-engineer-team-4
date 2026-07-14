import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/lessons/data/lesson_repository.dart';

import '../../../helpers/fake_asset_bundle.dart';
import '../../../helpers/result_helpers.dart';

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

LessonRepository buildRepository({
  String? lessonsAsset,
  double failureRate = 0.0,
}) =>
    LessonRepository(
      apiClient: ApiClient(
        bundle: FakeAssetBundle({
          if (lessonsAsset != null) ApiClient.lessonsAsset: lessonsAsset,
        }),
        failureRate: failureRate,
        latency: Duration.zero,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LessonRepository.getLessons', () {
    test('returns Success with typed lessons for a valid payload', () async {
      final repository = buildRepository(lessonsAsset: lessonsJson);

      final lessons = successValue(await repository.getLessons());

      expect(lessons, hasLength(2));
      expect(lessons.first.id, 'lesson-1');
      expect(lessons.last.topic, 'Dart');
    });

    test('returns NetworkFailure when the simulated network fails', () async {
      final repository = buildRepository(
        lessonsAsset: lessonsJson,
        failureRate: 1.0,
      );

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<NetworkFailure>());
    });

    test('returns DataParsingFailure for invalid JSON', () async {
      final repository = buildRepository(lessonsAsset: 'not json at all');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when the payload is not a list', () async {
      final repository = buildRepository(lessonsAsset: '{"lessons": []}');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns DataParsingFailure when an entry is malformed', () async {
      final repository = buildRepository(lessonsAsset: '[{"id": 1}]');

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<DataParsingFailure>());
    });

    test('returns UnexpectedFailure when the asset cannot be loaded', () async {
      final repository = buildRepository();

      final failure = failureOf(await repository.getLessons());

      expect(failure, isA<UnexpectedFailure>());
    });

    test('parses the real bundled lessons asset', () async {
      final repository = LessonRepository(
        apiClient: ApiClient(latency: Duration.zero),
      );

      final lessons = successValue(await repository.getLessons());

      expect(lessons, hasLength(3));
      expect(
        lessons.map((lesson) => lesson.id),
        containsAll(['lesson-1', 'lesson-2', 'lesson-3']),
      );
    });
  });
}
