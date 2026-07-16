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

  /// The most recent completion, or null before the first submission.
  QuizResult? get lastResult => _lastResult;

  /// Scores [selectedAnswers] against [quiz]; unanswered questions (`null`)
  /// count as wrong. Throws [ArgumentError] for an empty quiz or a mismatched
  /// answer count.
  Future<void> submitQuiz({
    required Quiz quiz,
    required List<int?> selectedAnswers,
  }) {
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
      if (selectedAnswers[index] == question.correctIndex) {
        score++;
      }
    }

    _lastResult = QuizResult(
      lessonId: quiz.lessonId,
      score: score,
      totalQuestions: quiz.questions.length,
      completedAt: _now(),
    );
    return _recordCompletion(quiz.lessonId).then((_) => notifyListeners());
  }
}
