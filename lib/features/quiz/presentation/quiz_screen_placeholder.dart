import 'package:flutter/material.dart';

/// Stands in for the real quiz experience until the quiz ticket lands.
class QuizScreenPlaceholder extends StatelessWidget {
  const QuizScreenPlaceholder({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz for lesson: $lessonId',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The quiz experience ships in a later ticket.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
