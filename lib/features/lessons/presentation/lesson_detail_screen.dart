import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/result/result.dart';
import '../../../core/routing/app_routes.dart';
import '../../quiz/data/quiz_repository.dart';
import '../../quiz/domain/quiz.dart';
import '../domain/lesson.dart';
import 'widgets/lesson_hero_image.dart';
import 'widgets/lesson_paragraphs.dart';
import 'widgets/quiz_cta_bar.dart';
import 'widgets/topic_chip.dart';

/// Displays a single [Lesson]'s content with a "Start Quiz" call to action.
///
/// The CTA is driven by [QuizRepository.getQuizByLessonId]: hidden when the
/// lesson has no quiz, and replaced by a retry affordance when the check
/// fails. The lesson content itself is always readable.
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    this.quizRepository,
  });

  final Lesson lesson;

  /// Overrides the locator-provided repository in tests.
  final QuizRepository? quizRepository;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late final QuizRepository _quizRepository;
  late Future<Result<Quiz?>> _quizFuture;

  @override
  void initState() {
    super.initState();
    _quizRepository = widget.quizRepository ?? locator<QuizRepository>();
    _quizFuture = _quizRepository.getQuizByLessonId(widget.lesson.id);
  }

  void _retryQuizCheck() {
    setState(() {
      _quizFuture = _quizRepository.getQuizByLessonId(widget.lesson.id);
    });
  }

  void _startQuiz() {
    Navigator.pushNamed(context, AppRoutes.quiz, arguments: widget.lesson.id);
  }

  /// Maps the check's snapshot to a CTA state; `null` hides the bar (the
  /// lesson has no quiz).
  QuizCtaState? _ctaState(AsyncSnapshot<Result<Quiz?>> snapshot) {
    // FutureBuilder retains the previous result while a retry is in flight,
    // so gate on connectionState rather than data alone.
    if (snapshot.connectionState != ConnectionState.done) {
      return QuizCtaState.loading;
    }
    return switch (snapshot.data) {
      null => QuizCtaState.loading,
      Success(value: null) => null,
      Success() => QuizCtaState.ready,
      Failure() => QuizCtaState.failed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Result<Quiz?>>(
      future: _quizFuture,
      builder: (context, snapshot) {
        final ctaState = _ctaState(snapshot);
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LessonHeroImage(
                  thumbnailUrl: widget.lesson.thumbnail,
                  semanticLabel: 'Illustration for ${widget.lesson.title}',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopicChip(topic: widget.lesson.topic),
                      const SizedBox(height: 16),
                      Text(
                        widget.lesson.title,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      LessonParagraphs(content: widget.lesson.content),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ctaState == null
              ? null
              : QuizCtaBar(
                  state: ctaState,
                  onStartQuiz: _startQuiz,
                  onRetry: _retryQuizCheck,
                ),
        );
      },
    );
  }
}
