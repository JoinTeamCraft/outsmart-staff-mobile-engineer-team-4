import 'package:get_it/get_it.dart';

import '../../features/lessons/data/lesson_repository.dart';
import '../../features/quiz/data/quiz_repository.dart';
import '../network/api_client.dart';

final GetIt locator = GetIt.instance;

const double _simulatedNetworkFailureRate = 0.15;

/// Registers the data layer. The nonzero failure rate keeps error handling
/// visible while running the app.
void setupLocator() {
  locator.registerLazySingleton<ApiClient>(
    () => ApiClient(failureRate: _simulatedNetworkFailureRate),
  );
  locator.registerLazySingleton<LessonRepository>(
    () => LessonRepository(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<QuizRepository>(
    () => QuizRepository(apiClient: locator<ApiClient>()),
  );
}
