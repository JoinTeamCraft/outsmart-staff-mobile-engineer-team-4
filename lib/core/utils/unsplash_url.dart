/// Rewrites an Unsplash thumbnail URL to a high-resolution variant suitable
/// for full-width hero display.
///
/// Non-Unsplash and malformed URLs are returned unchanged.
String upgradeUnsplashUrl(String url, {int width = 1200, int quality = 80}) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com') {
    return url;
  }
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'w': '$width',
    'q': '$quality',
    'auto': 'format',
    'fit': 'crop',
  }).toString();
}
