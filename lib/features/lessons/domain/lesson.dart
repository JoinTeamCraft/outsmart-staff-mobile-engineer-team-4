final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.thumbnail,
    required this.content,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'id': final String id,
          'title': final String title,
          'topic': final String topic,
          'thumbnail': final String thumbnail,
          'content': final String content,
        } =>
          Lesson(
            id: id,
            title: title,
            topic: topic,
            thumbnail: thumbnail,
            content: content,
          ),
        _ => throw FormatException('Malformed lesson JSON', json),
      };

  final String id;
  final String title;
  final String topic;
  final String thumbnail;
  final String content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          other.id == id &&
          other.title == title &&
          other.topic == topic &&
          other.thumbnail == thumbnail &&
          other.content == content;

  @override
  int get hashCode => Object.hash(id, title, topic, thumbnail, content);

  @override
  String toString() => 'Lesson($id, $title)';
}
