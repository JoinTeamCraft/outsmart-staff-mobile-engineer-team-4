import 'package:flutter/foundation.dart';

import '../domain/quiz.dart';
import '../domain/quiz_result.dart';

/// Scores submitted quizzes, records the completion for the streak, and
/// emits the [QuizResult] to subscribers.
class QuizSessionNotifier extends ChangeNotifier {
  QuizSessionNotifier({
    required Future<void> Function(String lessonId) recordCompletion,
    DateTime Function()? now,
  })  : _recordCompletion = recordCompletion,
        _now = now ?? DateTime.now;

  final Future<void> Function(String lessonId) _recordCompletion;
  final DateTime Function() _now;

  QuizResult? _lastResult;
  Object? _lastStreakRecordError;

  /// The most recent completion, or null before the first submission.
  QuizResult? get lastResult => _lastResult;

  /// The most recent streak-recording error, or null if it succeeded.
  /// Best-effort: doesn't block [lastResult] from notifying subscribers.
  Object? get lastStreakRecordError => _lastStreakRecordError;

  /// Scores [selectedAnswers] against [quiz]; `null` counts as wrong.
  /// Throws [ArgumentError] for malformed input.
  Future<void> submitQuiz({
    required Quiz quiz,
    required List<int?> selectedAnswers,
  }) async {
    if (quiz.questions.isEmpty) {
      throw ArgumentError.value(
        quiz,
        'quiz',
        'must have at least one question',
      );
    }
    if (selectedAnswers.length != quiz.questions.length) {
      throw ArgumentError.value(
        selectedAnswers.length,
        'selectedAnswers',
        'must match the ${quiz.questions.length} questions in the quiz',
      );
    }

    var score = 0;
    for (final (index, question) in quiz.questions.indexed) {
      final answer = selectedAnswers[index];
      if (answer != null && (answer < 0 || answer >= question.options.length)) {
        throw ArgumentError.value(
          answer,
          'selectedAnswers[$index]',
          'must be a valid option index for question ${question.id}',
        );
      }
      if (answer == question.correctIndex) {
        score++;
      }
    }

    _lastResult = QuizResult(
      lessonId: quiz.lessonId,
      score: score,
      totalQuestions: quiz.questions.length,
      completedAt: _now(),
    );

    try {
      await _recordCompletion(quiz.lessonId);
      _lastStreakRecordError = null;
    } catch (error) {
      _lastStreakRecordError = error;
      if (kDebugMode) debugPrint('QuizSessionNotifier: $error');
    }
    notifyListeners();
  }
}
