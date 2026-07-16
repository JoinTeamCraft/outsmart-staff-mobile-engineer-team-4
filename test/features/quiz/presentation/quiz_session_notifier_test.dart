import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaklearn/features/quiz/domain/quiz.dart';
import 'package:streaklearn/features/quiz/domain/quiz_result.dart';
import 'package:streaklearn/features/quiz/presentation/quiz_session_notifier.dart';
import 'package:streaklearn/features/streaks/data/streak_repository.dart';
import 'package:streaklearn/features/streaks/presentation/streak_notifier.dart';

const quiz = Quiz(
  lessonId: 'lesson-1',
  questions: [
    Question(
      id: 'q1',
      question: 'What is the core building block of a Flutter UI?',
      options: ['Widget', 'Activity', 'Component'],
      correctIndex: 0,
    ),
    Question(
      id: 'q2',
      question: 'Which tree handles layout and painting?',
      options: ['Widget Tree', 'Element Tree', 'RenderObject Tree'],
      correctIndex: 2,
    ),
  ],
);

QuizSessionNotifier buildSession({
  List<String>? completions,
  DateTime Function()? now,
}) =>
    QuizSessionNotifier(
      recordCompletion: (lessonId) async => completions?.add(lessonId),
      now: now,
    );

Future<(QuizSessionNotifier, StreakNotifier)> buildIntegratedSession() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final streak = StreakNotifier(
    repository: StreakRepository(preferences: preferences),
  );
  final session = QuizSessionNotifier(
    recordCompletion: streak.completeLesson,
  );
  return (session, streak);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizSessionNotifier.submitQuiz', () {
    test('scores all correct answers', () async {
      final session = buildSession();

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(session.lastResult?.score, 2);
      expect(session.lastResult?.totalQuestions, 2);
    });

    test('scores partially correct answers', () async {
      final session = buildSession();

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 1]);

      expect(session.lastResult?.score, 1);
    });

    test('counts unanswered questions as wrong', () async {
      final session = buildSession();

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, null]);

      expect(session.lastResult?.score, 1);
    });

    test('emits the complete payload to subscribers', () async {
      final completedAt = DateTime(2026, 7, 16, 12);
      final session = buildSession(now: () => completedAt);

      QuizResult? received;
      session.addListener(() => received = session.lastResult);

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(
        received,
        QuizResult(
          lessonId: 'lesson-1',
          score: 2,
          totalQuestions: 2,
          completedAt: completedAt,
        ),
      );
    });

    test('notifies once per submission', () async {
      final session = buildSession();

      var notifications = 0;
      session.addListener(() => notifications++);

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);
      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 1]);

      expect(notifications, 2);
    });

    test('records the completed lesson', () async {
      final completions = <String>[];
      final session = buildSession(completions: completions);

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(completions, ['lesson-1']);
    });

    test('notifies only after recordCompletion resolves', () async {
      final order = <String>[];
      final session = QuizSessionNotifier(
        recordCompletion: (lessonId) async {
          order.add('record-start');
          await Future<void>.delayed(Duration.zero);
          order.add('record-end');
        },
      );
      session.addListener(() => order.add('notified'));

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(order, ['record-start', 'record-end', 'notified']);
    });

    test('still emits the result when recordCompletion throws', () async {
      final session = QuizSessionNotifier(
        recordCompletion: (lessonId) async => throw StateError('save failed'),
      );

      var notifications = 0;
      session.addListener(() => notifications++);

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(session.lastResult?.score, 2);
      expect(notifications, 1);
      expect(session.lastStreakRecordError, isA<StateError>());
    });

    test('clears a previous streak record error once a submission succeeds',
        () async {
      var shouldFail = true;
      final session = QuizSessionNotifier(
        recordCompletion: (lessonId) async {
          if (shouldFail) throw StateError('save failed');
        },
      );

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);
      expect(session.lastStreakRecordError, isNotNull);

      shouldFail = false;
      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);
      expect(session.lastStreakRecordError, isNull);
    });

    test('throws ArgumentError for an out-of-range answer index', () {
      final session = buildSession();

      expect(
        () => session.submitQuiz(quiz: quiz, selectedAnswers: [0, 5]),
        throwsArgumentError,
      );
      expect(session.lastResult, isNull);
    });

    test('throws ArgumentError for a quiz with no questions', () {
      final session = buildSession();
      const empty = Quiz(lessonId: 'lesson-1', questions: []);

      expect(
        () => session.submitQuiz(quiz: empty, selectedAnswers: const []),
        throwsArgumentError,
      );
      expect(session.lastResult, isNull);
    });

    test('throws ArgumentError when answers do not match question count', () {
      final completions = <String>[];
      final session = buildSession(completions: completions);

      expect(
        () => session.submitQuiz(quiz: quiz, selectedAnswers: [0]),
        throwsArgumentError,
      );
      expect(session.lastResult, isNull);
      expect(completions, isEmpty);
    });
  });

  group('QuizSessionNotifier with the real streak stack', () {
    test('subscribers read the updated streak when notified', () async {
      final (session, streak) = await buildIntegratedSession();

      int? streakAtNotification;
      session.addListener(() => streakAtNotification = streak.streakCount);

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);

      expect(streakAtNotification, 1);
      expect(streak.isLessonCompleted('lesson-1'), isTrue);
    });

    test('retaking a quiz does not double count the streak', () async {
      final (session, streak) = await buildIntegratedSession();

      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 2]);
      await session.submitQuiz(quiz: quiz, selectedAnswers: [0, 1]);

      expect(streak.streakCount, 1);
      expect(session.lastResult?.score, 1);
    });
  });
}
