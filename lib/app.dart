import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/quiz/presentation/quiz_session_notifier.dart';
import 'features/streaks/presentation/streak_notifier.dart';

class StreakLearnApp extends StatelessWidget {
  const StreakLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    // .value: the notifiers are app-lifetime singletons owned by the locator,
    // so the providers must not dispose them.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StreakNotifier>.value(
          value: locator<StreakNotifier>(),
        ),
        ChangeNotifierProvider<QuizSessionNotifier>.value(
          value: locator<QuizSessionNotifier>(),
        ),
      ],
      child: MaterialApp(
        title: 'StreakLearn',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreenPlaceholder(),
        },
      ),
    );
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreakLearn')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Welcome to StreakLearn Hackathon!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tracks B, C, and D will replace this screen with the Lesson Feed, Lesson Detail/Quiz, and Streak Animation system.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
