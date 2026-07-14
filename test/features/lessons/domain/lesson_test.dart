import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/features/lessons/domain/lesson.dart';

const validJson = <String, dynamic>{
  'id': 'lesson-1',
  'title': 'Flutter Basics',
  'topic': 'Fundamentals',
  'thumbnail': 'https://example.com/thumb.png',
  'content': 'Everything is a widget.',
};

void main() {
  group('Lesson.fromJson', () {
    test('parses a valid payload', () {
      expect(
        Lesson.fromJson(validJson),
        const Lesson(
          id: 'lesson-1',
          title: 'Flutter Basics',
          topic: 'Fundamentals',
          thumbnail: 'https://example.com/thumb.png',
          content: 'Everything is a widget.',
        ),
      );
    });

    test('tolerates unknown extra fields', () {
      final lesson = Lesson.fromJson({...validJson, 'unknown': 42});

      expect(lesson.id, 'lesson-1');
    });

    test('throws FormatException when a field is missing', () {
      final json = Map<String, dynamic>.from(validJson)..remove('title');

      expect(() => Lesson.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when a field has the wrong type', () {
      expect(
        () => Lesson.fromJson({...validJson, 'title': 7}),
        throwsFormatException,
      );
    });

    test('throws FormatException when a field is null', () {
      expect(
        () => Lesson.fromJson({...validJson, 'content': null}),
        throwsFormatException,
      );
    });
  });
}
