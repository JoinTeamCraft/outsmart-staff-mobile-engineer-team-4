import 'package:flutter/material.dart';

/// Splits [content] into displayable paragraphs.
///
/// Prefers explicit structure: blank lines first, then single newlines.
/// Prose without newlines is grouped into two-sentence paragraphs so long
/// blobs still get visual rhythm.
List<String> splitIntoParagraphs(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final blankLineChunks = _chunks(trimmed, RegExp(r'\n\s*\n'));
  if (blankLineChunks.length > 1) {
    return blankLineChunks;
  }

  final lineChunks = _chunks(trimmed, '\n');
  if (lineChunks.length > 1) {
    return lineChunks;
  }

  final sentences = _chunks(trimmed, RegExp(r'(?<=[.!?])\s+'));
  final paragraphs = <String>[
    for (var i = 0; i < sentences.length; i += 2)
      sentences.skip(i).take(2).join(' '),
  ];
  return paragraphs.isEmpty ? [trimmed] : paragraphs;
}

List<String> _chunks(String text, Pattern separator) => [
      for (final chunk in text.split(separator))
        if (chunk.trim().isNotEmpty) chunk.trim(),
    ];

/// Lesson body text rendered as evenly spaced paragraphs.
class LessonParagraphs extends StatelessWidget {
  const LessonParagraphs({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, paragraph) in splitIntoParagraphs(content).indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
            child: Text(paragraph, style: style),
          ),
      ],
    );
  }
}
