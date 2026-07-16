import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/features/quiz/domain/quiz_result.dart';

void main() {
  final completedAt = DateTime(2026, 7, 16, 12);

  QuizResult buildResult({DateTime? at}) => QuizResult(
        lessonId: 'lesson-1',
        score: 2,
        totalQuestions: 3,
        completedAt: at ?? completedAt,
      );

  group('QuizResult', () {
    test('supports value equality', () {
      expect(buildResult(), buildResult());
    });

    test('consecutive results with identical scores differ by timestamp', () {
      final first = buildResult();
      final second = buildResult(
        at: completedAt.add(const Duration(minutes: 1)),
      );

      expect(first, isNot(second));
    });
  });
}
