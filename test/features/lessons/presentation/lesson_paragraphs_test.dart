import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/features/lessons/presentation/widgets/lesson_paragraphs.dart';

void main() {
  group('splitIntoParagraphs', () {
    test('splits on blank lines when present', () {
      expect(
        splitIntoParagraphs('First paragraph.\n\nSecond one.\n\n\nThird.'),
        ['First paragraph.', 'Second one.', 'Third.'],
      );
    });

    test('splits on single newlines when no blank lines exist', () {
      expect(
        splitIntoParagraphs('Line one.\nLine two.'),
        ['Line one.', 'Line two.'],
      );
    });

    test('groups plain prose into two-sentence paragraphs', () {
      const content = 'In Flutter, everything is a widget. '
          'Widgets are nested to build the UI structure. '
          'The widget tree consists of structural, stylistic, and behavioral elements.';

      expect(splitIntoParagraphs(content), [
        'In Flutter, everything is a widget. '
            'Widgets are nested to build the UI structure.',
        'The widget tree consists of structural, stylistic, and behavioral elements.',
      ]);
    });

    test('keeps a single sentence as one paragraph', () {
      expect(
        splitIntoParagraphs('Just one sentence.'),
        ['Just one sentence.'],
      );
    });

    test('returns no paragraphs for empty or whitespace-only content', () {
      expect(splitIntoParagraphs(''), isEmpty);
      expect(splitIntoParagraphs('   '), isEmpty);
    });
  });
}
