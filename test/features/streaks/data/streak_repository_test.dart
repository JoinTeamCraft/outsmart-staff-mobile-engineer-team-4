import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/streaks/data/streak_repository.dart';
import 'package:streaklearn/features/streaks/domain/streak_data.dart';

import '../../../helpers/result_helpers.dart';

Future<StreakRepository> buildRepository([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return StreakRepository(preferences: await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakRepository.load', () {
    test('returns Success(empty) on a fresh install with no stored keys',
        () async {
      final repository = await buildRepository();

      final data = successValue(await repository.load());

      expect(data, StreakData.empty);
    });

    test('returns Success with the stored streak and lesson ids', () async {
      final repository = await buildRepository({
        StreakRepository.streakCountKey: 5,
        StreakRepository.completedLessonIdsKey: ['lesson-1', 'lesson-2'],
      });

      final data = successValue(await repository.load());

      expect(data.streakCount, 5);
      expect(data.completedLessonIds, {'lesson-1', 'lesson-2'});
    });

    test('defaults each key independently when the other is absent', () async {
      final countOnly = await buildRepository({
        StreakRepository.streakCountKey: 3,
      });
      final idsOnly = await buildRepository({
        StreakRepository.completedLessonIdsKey: ['lesson-1'],
      });

      final countData = successValue(await countOnly.load());
      final idsData = successValue(await idsOnly.load());

      expect(countData.streakCount, 3);
      expect(countData.completedLessonIds, isEmpty);
      expect(idsData.streakCount, 0);
      expect(idsData.completedLessonIds, {'lesson-1'});
    });

    test('deduplicates lesson ids stored with duplicates', () async {
      final repository = await buildRepository({
        StreakRepository.completedLessonIdsKey: [
          'lesson-1',
          'lesson-1',
          'lesson-2',
        ],
      });

      final data = successValue(await repository.load());

      expect(data.completedLessonIds, {'lesson-1', 'lesson-2'});
    });

    test('returns StorageFailure for a negative stored streak count',
        () async {
      final repository = await buildRepository({
        StreakRepository.streakCountKey: -1,
      });

      final failure = failureOf(await repository.load());

      expect(failure, isA<StorageFailure>());
    });

    test('returns StorageFailure for a wrong-typed stored value', () async {
      final repository = await buildRepository({
        StreakRepository.streakCountKey: 'not-a-number',
      });

      final failure = failureOf(await repository.load());

      expect(failure, isA<StorageFailure>());
    });
  });

  group('StreakRepository.save', () {
    test('round-trips: load returns what save persisted', () async {
      final repository = await buildRepository();
      final data = StreakData(
        streakCount: 4,
        completedLessonIds: {'lesson-1', 'lesson-3'},
      );

      successValue(await repository.save(data));

      expect(successValue(await repository.load()), data);
    });

    test('overwrites previously stored values', () async {
      final repository = await buildRepository({
        StreakRepository.streakCountKey: 1,
        StreakRepository.completedLessonIdsKey: ['lesson-1'],
      });
      final updated = StreakData(
        streakCount: 2,
        completedLessonIds: {'lesson-1', 'lesson-2'},
      );

      successValue(await repository.save(updated));

      expect(successValue(await repository.load()), updated);
    });
  });
}
