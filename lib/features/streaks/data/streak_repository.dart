import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/result/result.dart';
import '../domain/streak_data.dart';

/// Persists streak progress in local key-value storage and maps every
/// outcome to a [Result].
class StreakRepository {
  const StreakRepository({required SharedPreferences preferences})
      : _preferences = preferences;

  static const String streakCountKey = 'streaks.streakCount';
  static const String completedLessonIdsKey = 'streaks.completedLessonIds';

  final SharedPreferences _preferences;

  /// Loads the persisted streak progress. Absent keys are not an error: a
  /// fresh install resolves to `Success(StreakData.empty)`. Never throws.
  Future<Result<StreakData>> load() async {
    try {
      final streakCount = _preferences.getInt(streakCountKey) ?? 0;
      if (streakCount < 0) {
        return Failure(
          StorageFailure('Stored streak count is invalid: $streakCount'),
        );
      }
      final completedLessonIds =
          _preferences.getStringList(completedLessonIdsKey) ?? const [];
      return Success(
        StreakData(
          streakCount: streakCount,
          completedLessonIds: completedLessonIds.toSet(),
        ),
      );
    } catch (exception) {
      return Failure(StorageFailure('$exception'));
    }
  }

  /// Persists [data], writing both keys together so they cannot drift.
  /// Never throws.
  Future<Result<void>> save(StreakData data) async {
    try {
      final wroteCount =
          await _preferences.setInt(streakCountKey, data.streakCount);
      final wroteIds = await _preferences.setStringList(
        completedLessonIdsKey,
        data.completedLessonIds.toList(),
      );
      if (!wroteCount || !wroteIds) {
        return const Failure(StorageFailure('Failed to write streak data.'));
      }
      return const Success(null);
    } catch (exception) {
      return Failure(StorageFailure('$exception'));
    }
  }
}
