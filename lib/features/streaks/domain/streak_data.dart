import 'package:flutter/foundation.dart';

/// The user's streak progress: the current streak count and the set of
/// lessons they have completed.
final class StreakData {
  StreakData({
    required this.streakCount,
    required Set<String> completedLessonIds,
  }) : completedLessonIds = Set.unmodifiable(completedLessonIds);

  /// The state of a fresh install: no streak, no completed lessons.
  static final StreakData empty =
      StreakData(streakCount: 0, completedLessonIds: const {});

  final int streakCount;
  final Set<String> completedLessonIds;

  bool isLessonCompleted(String lessonId) =>
      completedLessonIds.contains(lessonId);

  /// Returns a copy with [lessonId] recorded and the streak incremented, or
  /// `this` when the lesson was already completed.
  StreakData completeLesson(String lessonId) {
    if (isLessonCompleted(lessonId)) {
      return this;
    }
    return StreakData(
      streakCount: streakCount + 1,
      completedLessonIds: {...completedLessonIds, lessonId},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakData &&
          other.streakCount == streakCount &&
          setEquals(other.completedLessonIds, completedLessonIds);

  @override
  int get hashCode =>
      Object.hash(streakCount, Object.hashAllUnordered(completedLessonIds));

  @override
  String toString() =>
      'StreakData(streak: $streakCount, '
      '${completedLessonIds.length} lessons completed)';
}
