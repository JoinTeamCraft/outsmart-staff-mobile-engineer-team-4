import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/features/quiz/domain/quiz.dart';

const validQuestionJson = <String, dynamic>{
  'id': 'q1',
  'question': 'What is the core building block of a Flutter UI?',
  'options': ['Widget', 'Activity', 'Component', 'View'],
  'correctIndex': 0,
};

void main() {
  group('Question.fromJson', () {
    test('parses a valid payload', () {
      expect(
        Question.fromJson(validQuestionJson),
        const Question(
          id: 'q1',
          question: 'What is the core building block of a Flutter UI?',
          options: ['Widget', 'Activity', 'Component', 'View'],
          correctIndex: 0,
        ),
      );
    });

    test('throws FormatException when a field is missing', () {
      final json = Map<String, dynamic>.from(validQuestionJson)
        ..remove('options');

      expect(() => Question.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when an option is not a string', () {
      expect(
        () => Question.fromJson({
          ...validQuestionJson,
          'options': ['Widget', 3],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when options are empty', () {
      expect(
        () => Question.fromJson({...validQuestionJson, 'options': <Object?>[]}),
        throwsFormatException,
      );
    });

    test('throws FormatException when correctIndex is out of range', () {
      expect(
        () => Question.fromJson({...validQuestionJson, 'correctIndex': 4}),
        throwsFormatException,
      );
      expect(
        () => Question.fromJson({...validQuestionJson, 'correctIndex': -1}),
        throwsFormatException,
      );
    });
  });

  group('Quiz.fromJson', () {
    test('parses a valid payload with nested questions', () {
      final quiz = Quiz.fromJson({
        'lessonId': 'lesson-1',
        'questions': [validQuestionJson],
      });

      expect(quiz.lessonId, 'lesson-1');
      expect(quiz.questions, hasLength(1));
      expect(quiz.questions.first.id, 'q1');
    });

    test('throws FormatException when lessonId is missing', () {
      expect(
        () => Quiz.fromJson({'questions': <Object?>[]}),
        throwsFormatException,
      );
    });

    test('propagates FormatException from a malformed nested question', () {
      expect(
        () => Quiz.fromJson({
          'lessonId': 'lesson-1',
          'questions': [
            {'id': 'q1'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
