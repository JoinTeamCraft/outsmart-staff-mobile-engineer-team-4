/// The outcome of one completed quiz; [completedAt] distinguishes
/// consecutive results with identical scores.
final class QuizResult {
  const QuizResult({
    required this.lessonId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  }) : assert(
          score >= 0 && score <= totalQuestions,
          'score must be within 0..totalQuestions',
        );

  final String lessonId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizResult &&
          other.lessonId == lessonId &&
          other.score == score &&
          other.totalQuestions == totalQuestions &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(lessonId, score, totalQuestions, completedAt);

  @override
  String toString() =>
      'QuizResult($lessonId, $score/$totalQuestions, $completedAt)';
}
