import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/result/result.dart';
import '../domain/lesson.dart';

/// Loads lessons from the mock API and maps every outcome to a [Result].
class LessonRepository {
  const LessonRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetches all lessons. Never throws: network, parsing, and unexpected
  /// errors come back as a [Failure].
  Future<Result<List<Lesson>>> getLessons() async {
    try {
      final raw = await _apiClient.getLessonsRaw();
      final lessons = switch (jsonDecode(raw)) {
        final List<Object?> entries => [
            for (final entry in entries)
              switch (entry) {
                final Map<String, dynamic> json => Lesson.fromJson(json),
                _ => throw FormatException('Malformed lesson entry', entry),
              },
          ],
        final other =>
          throw FormatException('Expected a list of lessons', other),
      };
      return Success(lessons);
    } on NetworkException catch (exception) {
      return Failure(NetworkFailure(exception.message));
    } on FormatException catch (exception) {
      return Failure(DataParsingFailure(exception.message));
    } catch (exception) {
      return Failure(UnexpectedFailure('$exception'));
    }
  }
}
