import 'dart:convert';

import '../../../core/cache/cached_resource.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/result/result.dart';
import '../domain/lesson.dart';

/// Loads lessons from the mock API; successes are cached, nothing throws.
class LessonRepository {
  LessonRepository({
    required ApiClient apiClient,
    required CachedResource<List<Lesson>> cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CachedResource<List<Lesson>> _cache;

  /// Fetches all lessons; [forceRefresh] (pull-to-refresh) skips the cache.
  Future<Result<List<Lesson>>> getLessons({bool forceRefresh = false}) =>
      _cache.get(_fetchLessons, forceRefresh: forceRefresh);

  Future<Result<List<Lesson>>> _fetchLessons() async {
    try {
      final raw = await _apiClient.getLessonsRaw();
      final lessons = List<Lesson>.unmodifiable(
        switch (jsonDecode(raw)) {
          final List<Object?> entries => [
              for (final entry in entries)
                switch (entry) {
                  final Map<String, dynamic> json => Lesson.fromJson(json),
                  _ => throw FormatException('Malformed lesson entry', entry),
                },
            ],
          final other =>
            throw FormatException('Expected a list of lessons', other),
        },
      );
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
