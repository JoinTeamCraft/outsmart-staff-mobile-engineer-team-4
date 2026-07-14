import 'package:flutter/foundation.dart';

final class Quiz {
  const Quiz({required this.lessonId, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'lessonId': final String lessonId,
          'questions': final List<Object?> questions,
        } =>
          Quiz(
            lessonId: lessonId,
            questions: [
              for (final question in questions)
                switch (question) {
                  final Map<String, dynamic> entry => Question.fromJson(entry),
                  _ =>
                    throw FormatException('Malformed question entry', question),
                },
            ],
          ),
        _ => throw FormatException('Malformed quiz JSON', json),
      };

  final String lessonId;
  final List<Question> questions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quiz &&
          other.lessonId == lessonId &&
          listEquals(other.questions, questions);

  @override
  int get hashCode => Object.hash(lessonId, Object.hashAll(questions));

  @override
  String toString() => 'Quiz($lessonId, ${questions.length} questions)';
}

final class Question {
  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final (id, question, rawOptions, correctIndex) = switch (json) {
      {
        'id': final String id,
        'question': final String question,
        'options': final List<Object?> options,
        'correctIndex': final int correctIndex,
      } =>
        (id, question, options, correctIndex),
      _ => throw FormatException('Malformed question JSON', json),
    };

    final options = <String>[
      for (final option in rawOptions)
        switch (option) {
          final String value => value,
          _ => throw FormatException('Question options must be strings', json),
        },
    ];

    if (options.isEmpty) {
      throw FormatException('Question requires at least one option', json);
    }
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw FormatException(
        'correctIndex $correctIndex is out of range for '
        '${options.length} options',
        json,
      );
    }

    return Question(
      id: id,
      question: question,
      options: options,
      correctIndex: correctIndex,
    );
  }

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          other.id == id &&
          other.question == question &&
          listEquals(other.options, options) &&
          other.correctIndex == correctIndex;

  @override
  int get hashCode =>
      Object.hash(id, question, Object.hashAll(options), correctIndex);

  @override
  String toString() => 'Question($id)';
}
