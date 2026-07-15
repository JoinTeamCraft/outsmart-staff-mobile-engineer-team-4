import 'dart:convert';

import '../../../core/cache/cached_resource.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/result/result.dart';
import '../domain/quiz.dart';

/// Loads quizzes from the mock API, cached as one payload keyed by lesson id.
class QuizRepository {
  QuizRepository({
    required ApiClient apiClient,
    required CachedResource<Map<String, Quiz>> cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CachedResource<Map<String, Quiz>> _cache;

  /// Finds the quiz for [lessonId]; `Success(null)` means the lesson has none.
  Future<Result<Quiz?>> getQuizByLessonId(
    String lessonId, {
    bool forceRefresh = false,
  }) async {
    final result = await _cache.get(_fetchQuizzes, forceRefresh: forceRefresh);
    return switch (result) {
      Success(:final value) => Success(value[lessonId]),
      Failure(:final failure) => Failure(failure),
    };
  }

  Future<Result<Map<String, Quiz>>> _fetchQuizzes() async {
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

      final byLessonId = <String, Quiz>{};
      for (final quiz in quizzes) {
        byLessonId.putIfAbsent(quiz.lessonId, () => quiz);
      }
      return Success(Map<String, Quiz>.unmodifiable(byLessonId));
    } on NetworkException catch (exception) {
      return Failure(NetworkFailure(exception.message));
    } on FormatException catch (exception) {
      return Failure(DataParsingFailure(exception.message));
    } catch (exception) {
      return Failure(UnexpectedFailure('$exception'));
    }
  }
}
