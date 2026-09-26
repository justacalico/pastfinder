class Paste {
  Paste({
    required this.source,
    required this.id,
    required this.title,
    required this.url,
    required this.fetchedAt,
    this.author = '',
    this.rawUrl,
    this.createdAt,
    this.content,
  });

  /// Source id, e.g. `github_gists`.
  final String source;

  /// Remote identifier on the source service.
  final String id;
  final String title;
  final String author;
  final String url;
  final String? rawUrl;
  final DateTime? createdAt;
  final DateTime fetchedAt;
  String? content;

  String get key => '$source:$id';
  bool get hasContent => content != null;

  Map<String, dynamic> toJson() => {
        'source': source,
        'id': id,
        'title': title,
        'author': author,
        'url': url,
        'rawUrl': rawUrl,
        'createdAt': createdAt?.toIso8601String(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'content': content,
      };

  factory Paste.fromJson(Map<String, dynamic> json) => Paste(
        source: json['source'] as String? ?? '',
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        url: json['url'] as String? ?? '',
        rawUrl: json['rawUrl'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.now(),
        content: json['content'] as String?,
      );
}
