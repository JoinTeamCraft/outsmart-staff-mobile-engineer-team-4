import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../data/streak_repository.dart';
import '../domain/streak_data.dart';

/// Holds the in-memory streak state for the UI and keeps it in sync with
/// [StreakRepository].
class StreakNotifier extends ChangeNotifier {
  StreakNotifier({required StreakRepository repository})
      : _repository = repository;

  final StreakRepository _repository;

  StreakData _data = StreakData.empty;
  AppFailure? _lastFailure;

  int get streakCount => _data.streakCount;
  Set<String> get completedLessonIds => _data.completedLessonIds;

  /// The most recent storage failure, or null. The app keeps running on
  /// failures; this lets the UI surface them if it wants to.
  AppFailure? get lastFailure => _lastFailure;

  bool isLessonCompleted(String lessonId) => _data.isLessonCompleted(lessonId);

  /// Loads the persisted state. On failure the state stays [StreakData.empty]
  /// so the app still boots, and [lastFailure] records why.
  Future<void> hydrate() async {
    switch (await _repository.load()) {
      case Success(:final value):
        _data = value;
        _lastFailure = null;
      case Failure(:final failure):
        _lastFailure = failure;
    }
    notifyListeners();
  }

  /// Records [lessonId] as completed and persists the new state. Completing
  /// an already-completed lesson is a no-op.
  Future<void> completeLesson(String lessonId) async {
    if (isLessonCompleted(lessonId)) {
      return;
    }
    _data = _data.completeLesson(lessonId);
    notifyListeners();

    switch (await _repository.save(_data)) {
      case Success():
        break;
      case Failure(:final failure):
        // Keep the in-memory state so the session stays consistent; only the
        // next launch would miss this update.
        _lastFailure = failure;
        notifyListeners();
    }
  }
}
