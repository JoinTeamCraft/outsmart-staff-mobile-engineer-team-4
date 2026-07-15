import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'core/result/result.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/lessons/data/lesson_repository.dart';
import 'features/lessons/domain/lesson.dart';
import 'features/lessons/presentation/lesson_detail_screen.dart';
import 'features/quiz/presentation/quiz_screen_placeholder.dart';

class StreakLearnApp extends StatelessWidget {
  const StreakLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreakLearn',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomeScreenPlaceholder(),
      },
      onGenerateRoute: (settings) => switch (settings.name) {
        AppRoutes.lessonDetail => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                LessonDetailScreen(lesson: settings.arguments! as Lesson),
          ),
        AppRoutes.quiz => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                QuizScreenPlaceholder(lessonId: settings.arguments! as String),
          ),
        _ => null,
      },
    );
  }
}

class HomeScreenPlaceholder extends StatefulWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  State<HomeScreenPlaceholder> createState() => _HomeScreenPlaceholderState();
}

class _HomeScreenPlaceholderState extends State<HomeScreenPlaceholder> {
  List<Lesson> _lessons = const [];
  bool _loading = false;

  Future<void> _loadLessons() async {
    setState(() => _loading = true);
    final result = await locator<LessonRepository>().getLessons();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    switch (result) {
      case Success(value: final lessons):
        setState(() => _lessons = lessons);
      case Failure(failure: final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreakLearn')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'Welcome to StreakLearn Hackathon!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tracks B, C, and D will replace this screen with the Lesson Feed, Lesson Detail/Quiz, and Streak Animation system.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // TODO: remove when Track B lands the lesson feed.
            if (_lessons.isEmpty)
              OutlinedButton(
                onPressed: _loading ? null : _loadLessons,
                child: Text(
                  _loading ? 'Loading lessons...' : 'Preview lesson detail (dev)',
                ),
              )
            else
              for (final lesson in _lessons)
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.lessonDetail,
                    arguments: lesson,
                  ),
                  child: Text(lesson.title),
                ),
          ],
        ),
      ),
    );
  }
}
