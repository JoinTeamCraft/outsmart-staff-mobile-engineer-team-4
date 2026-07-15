import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/routing/app_routes.dart';
import 'package:streaklearn/core/theme/app_theme.dart';
import 'package:streaklearn/features/lessons/domain/lesson.dart';
import 'package:streaklearn/features/lessons/presentation/lesson_detail_screen.dart';
import 'package:streaklearn/features/quiz/data/quiz_repository.dart';

import '../../../helpers/fake_asset_bundle.dart';

const lesson = Lesson(
  id: 'lesson-1',
  title: 'Flutter Basics & Widgets',
  topic: 'Fundamentals',
  thumbnail: 'https://images.unsplash.com/photo-123?w=200',
  content: 'In Flutter, everything is a widget. '
      'Widgets are nested to build the UI structure. '
      'The widget tree consists of structural, stylistic, and behavioral elements.',
);

const quizzesJson = '''
[
  {
    "lessonId": "lesson-1",
    "questions": [
      {
        "id": "q1",
        "question": "What is the core building block of a Flutter UI?",
        "options": ["Widget", "Activity"],
        "correctIndex": 0
      }
    ]
  }
]
''';

QuizRepository buildRepository({double failureRate = 0.0}) => QuizRepository(
      apiClient: ApiClient(
        bundle: FakeAssetBundle({ApiClient.quizzesAsset: quizzesJson}),
        failureRate: failureRate,
        latency: Duration.zero,
      ),
    );

Future<void> pumpScreen(
  WidgetTester tester, {
  required QuizRepository repository,
  Lesson subject = lesson,
  List<Object?>? quizRouteArguments,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.quiz) {
          quizRouteArguments?.add(settings.arguments);
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('stub quiz route')),
          );
        }
        return null;
      },
      home: LessonDetailScreen(lesson: subject, quizRepository: repository),
    ),
  );
}

void main() {
  testWidgets('renders title, topic chip, and paragraphs', (tester) async {
    await pumpScreen(tester, repository: buildRepository());
    await tester.pumpAndSettle();

    expect(find.text(lesson.title), findsOneWidget);
    expect(find.text(lesson.topic.toUpperCase()), findsOneWidget);
    expect(
      find.textContaining('In Flutter, everything is a widget.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The widget tree consists of structural'),
      findsOneWidget,
    );
  });

  testWidgets('falls back to a placeholder icon when the hero image fails',
      (tester) async {
    await pumpScreen(tester, repository: buildRepository());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('shows a disabled CTA while the quiz check is loading',
      (tester) async {
    await pumpScreen(tester, repository: buildRepository());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Checking quiz...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
  });

  testWidgets('enables Start Quiz when the lesson has a quiz',
      (tester) async {
    await pumpScreen(tester, repository: buildRepository());
    await tester.pumpAndSettle();

    expect(find.text('Start Quiz'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('hides the CTA entirely when the lesson has no quiz',
      (tester) async {
    const quizlessLesson = Lesson(
      id: 'lesson-3',
      title: 'State Management',
      topic: 'Architecture',
      thumbnail: 'https://images.unsplash.com/photo-456?w=200',
      content: 'Some content.',
    );

    await pumpScreen(
      tester,
      repository: buildRepository(),
      subject: quizlessLesson,
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Quiz'), findsNothing);
    expect(find.text('Checking quiz...'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows retry on failure while keeping the content readable',
      (tester) async {
    await pumpScreen(tester, repository: buildRepository(failureRate: 1.0));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't check for a quiz"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text(lesson.title), findsOneWidget);
  });

  testWidgets('tapping Retry re-runs the quiz check', (tester) async {
    await pumpScreen(tester, repository: buildRepository(failureRate: 1.0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.text('Checking quiz...'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping Start Quiz navigates to the quiz route with the id',
      (tester) async {
    final arguments = <Object?>[];
    await pumpScreen(
      tester,
      repository: buildRepository(),
      quizRouteArguments: arguments,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('stub quiz route'), findsOneWidget);
    expect(arguments, [lesson.id]);
  });
}
