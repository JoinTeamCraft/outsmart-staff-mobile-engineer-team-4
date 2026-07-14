import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/lessons/data/lesson_repository.dart';
import '../../features/quiz/data/quiz_repository.dart';
import '../../features/streaks/data/streak_repository.dart';
import '../../features/streaks/presentation/streak_notifier.dart';
import '../network/api_client.dart';

final GetIt locator = GetIt.instance;

const double _simulatedNetworkFailureRate = 0.15;

/// Registers the data layer. The nonzero failure rate keeps error handling
/// visible while running the app. [preferences] is passed in already awaited
/// so registration stays synchronous.
void setupLocator({required SharedPreferences preferences}) {
  locator.registerSingleton<SharedPreferences>(preferences);
  locator.registerLazySingleton<ApiClient>(
    () => ApiClient(failureRate: _simulatedNetworkFailureRate),
  );
  locator.registerLazySingleton<LessonRepository>(
    () => LessonRepository(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<QuizRepository>(
    () => QuizRepository(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<StreakRepository>(
    () => StreakRepository(preferences: locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<StreakNotifier>(
    () => StreakNotifier(repository: locator<StreakRepository>()),
  );
}
