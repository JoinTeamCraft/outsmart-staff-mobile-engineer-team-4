import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/result/result.dart';
import '../domain/quiz.dart';

/// Loads quizzes from the mock API and maps every outcome to a [Result].
class QuizRepository {
  const QuizRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Finds the quiz for [lessonId]. Resolves to `Success(null)` when the
  /// lesson has no quiz; never throws.
  Future<Result<Quiz?>> getQuizByLessonId(String lessonId) async {
    try {
      final raw = await _apiClient.getQuizzesRaw();
      final quizzes = switch (jsonDecode(raw)) {
        final List<Object?> entries => [
            for (final entry in entries)
              switch (entry) {
                final Map<String, dynamic> json => Quiz.fromJson(json),
                _ => throw FormatException('Malformed quiz entry', entry),
              },
          ],
        final other =>
          throw FormatException('Expected a list of quizzes', other),
      };

      for (final quiz in quizzes) {
        if (quiz.lessonId == lessonId) {
          return Success(quiz);
        }
      }
      return const Success(null);
    } on NetworkException catch (exception) {
      return Failure(NetworkFailure(exception.message));
    } on FormatException catch (exception) {
      return Failure(DataParsingFailure(exception.message));
    } catch (exception) {
      return Failure(UnexpectedFailure('$exception'));
    }
  }
}
