import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/features/streaks/domain/streak_data.dart';

void main() {
  group('StreakData.empty', () {
    test('has no streak and no completed lessons', () {
      expect(StreakData.empty.streakCount, 0);
      expect(StreakData.empty.completedLessonIds, isEmpty);
      expect(StreakData.empty.isLessonCompleted('lesson-1'), isFalse);
    });
  });

  group('StreakData.completeLesson', () {
    test('records the lesson and increments the streak', () {
      final data = StreakData.empty.completeLesson('lesson-1');

      expect(data.streakCount, 1);
      expect(data.completedLessonIds, {'lesson-1'});
      expect(data.isLessonCompleted('lesson-1'), isTrue);
    });

    test('returns this unchanged for an already-completed lesson', () {
      final data = StreakData.empty.completeLesson('lesson-1');

      final again = data.completeLesson('lesson-1');

      expect(again, same(data));
      expect(again.streakCount, 1);
    });

    test('does not mutate the original instance', () {
      final original = StreakData.empty.completeLesson('lesson-1');

      original.completeLesson('lesson-2');

      expect(original.streakCount, 1);
      expect(original.completedLessonIds, {'lesson-1'});
    });
  });

  group('StreakData invariants', () {
    test('completedLessonIds is unmodifiable', () {
      final data = StreakData(
        streakCount: 1,
        completedLessonIds: {'lesson-1'},
      );

      expect(
        () => data.completedLessonIds.add('lesson-2'),
        throwsUnsupportedError,
      );
    });

    test('is not affected by mutations to the source set', () {
      final source = {'lesson-1'};
      final data = StreakData(streakCount: 1, completedLessonIds: source);

      source.add('lesson-2');

      expect(data.completedLessonIds, {'lesson-1'});
    });

    test('equality ignores set ordering', () {
      final a = StreakData(
        streakCount: 2,
        completedLessonIds: {'lesson-1', 'lesson-2'},
      );
      final b = StreakData(
        streakCount: 2,
        completedLessonIds: {'lesson-2', 'lesson-1'},
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differing count or ids are unequal', () {
      final base = StreakData(
        streakCount: 1,
        completedLessonIds: {'lesson-1'},
      );

      expect(
        base,
        isNot(StreakData(streakCount: 2, completedLessonIds: {'lesson-1'})),
      );
      expect(
        base,
        isNot(StreakData(streakCount: 1, completedLessonIds: {'lesson-2'})),
      );
    });
  });
}
