import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaklearn/core/result/result.dart';
import 'package:streaklearn/features/streaks/data/streak_repository.dart';
import 'package:streaklearn/features/streaks/presentation/streak_notifier.dart';

Future<StreakNotifier> buildNotifier([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return StreakNotifier(
    repository: StreakRepository(
      preferences: await SharedPreferences.getInstance(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakNotifier.hydrate', () {
    test('populates state from stored values and notifies', () async {
      final notifier = await buildNotifier({
        StreakRepository.streakCountKey: 7,
        StreakRepository.completedLessonIdsKey: ['lesson-1', 'lesson-2'],
      });
      var notifications = 0;
      notifier.addListener(() => notifications++);

      await notifier.hydrate();

      expect(notifier.streakCount, 7);
      expect(notifier.completedLessonIds, {'lesson-1', 'lesson-2'});
      expect(notifier.isLessonCompleted('lesson-1'), isTrue);
      expect(notifier.lastFailure, isNull);
      expect(notifications, 1);
    });

    test('keeps empty state and records the failure on corrupt storage',
        () async {
      final notifier = await buildNotifier({
        StreakRepository.streakCountKey: -5,
      });

      await notifier.hydrate();

      expect(notifier.streakCount, 0);
      expect(notifier.completedLessonIds, isEmpty);
      expect(notifier.lastFailure, isA<StorageFailure>());
    });
  });

  group('StreakNotifier.completeLesson', () {
    test('updates state, notifies, and persists', () async {
      final notifier = await buildNotifier();
      await notifier.hydrate();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      await notifier.completeLesson('lesson-1');

      expect(notifier.streakCount, 1);
      expect(notifier.isLessonCompleted('lesson-1'), isTrue);
      expect(notifier.lastFailure, isNull);
      expect(notifications, 1);

      // A fresh notifier over the same preferences sees the persisted state.
      final rehydrated = StreakNotifier(
        repository: StreakRepository(
          preferences: await SharedPreferences.getInstance(),
        ),
      );
      await rehydrated.hydrate();
      expect(rehydrated.streakCount, 1);
      expect(rehydrated.completedLessonIds, {'lesson-1'});
    });

    test('is a no-op for an already-completed lesson', () async {
      final notifier = await buildNotifier({
        StreakRepository.streakCountKey: 1,
        StreakRepository.completedLessonIdsKey: ['lesson-1'],
      });
      await notifier.hydrate();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      await notifier.completeLesson('lesson-1');

      expect(notifier.streakCount, 1);
      expect(notifier.completedLessonIds, {'lesson-1'});
      expect(notifications, 0);
    });

    test('completing distinct lessons grows the streak', () async {
      final notifier = await buildNotifier();
      await notifier.hydrate();

      await notifier.completeLesson('lesson-1');
      await notifier.completeLesson('lesson-2');
      await notifier.completeLesson('lesson-1');

      expect(notifier.streakCount, 2);
      expect(notifier.completedLessonIds, {'lesson-1', 'lesson-2'});
    });
  });
}
