import 'package:flutter/material.dart';

/// Outcome of the quiz-availability check that drives [QuizCtaBar].
enum QuizCtaState {
  /// The check is still running.
  loading,

  /// A quiz exists for the lesson.
  ready,

  /// The check failed; offer a retry.
  failed,
}

/// Sticky bottom bar hosting the "Start Quiz" call to action.
class QuizCtaBar extends StatelessWidget {
  const QuizCtaBar({
    super.key,
    required this.state,
    required this.onStartQuiz,
    required this.onRetry,
  });

  final QuizCtaState state;
  final VoidCallback onStartQuiz;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: switch (state) {
            QuizCtaState.loading => const SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Checking quiz...'),
                    ],
                  ),
                ),
              ),
            QuizCtaState.ready => SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onStartQuiz,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Quiz'),
                ),
              ),
            QuizCtaState.failed => Row(
                children: [
                  Expanded(
                    child: Text(
                      "Couldn't check for a quiz",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
