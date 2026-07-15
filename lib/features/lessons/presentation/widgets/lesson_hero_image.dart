import 'package:flutter/material.dart';

import '../../../../core/utils/unsplash_url.dart';

/// Full-width 16:9 lesson illustration with loading and error placeholders.
class LessonHeroImage extends StatelessWidget {
  const LessonHeroImage({
    super.key,
    required this.thumbnailUrl,
    required this.semanticLabel,
  });

  final String thumbnailUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          upgradeUnsplashUrl(thumbnailUrl),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  value: switch (loadingProgress.expectedTotalBytes) {
                    final int total =>
                      loadingProgress.cumulativeBytesLoaded / total,
                    null => null,
                  },
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
