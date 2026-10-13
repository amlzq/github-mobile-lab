import '../../../../domain/models/code.dart';

/// REST representation of a code search item.
///
/// Requires the `application/vnd.github.text-match+json` Accept header to
/// receive [textMatches].
class CodeApiModel {
  const CodeApiModel({
    required this.fileName,
    required this.repoFullName,
    required this.path,
    required this.ownerAvatarUrl,
    this.language,
    this.textMatches = const [],
  });

  final String fileName;
  final String repoFullName;
  final String path;
  final String ownerAvatarUrl;
  final String? language;
  final List<CodeTextMatch> textMatches;

  factory CodeApiModel.fromJson(Map<String, dynamic> json) {
    final repo = json['repository'] as Map<String, dynamic>?;
    final owner = repo?['owner'] as Map<String, dynamic>?;
    final matches =
        ((json['text_matches'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_parseTextMatch)
            .toList();
    return CodeApiModel(
      fileName: json['name'] as String? ?? '',
      repoFullName: repo?['full_name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      ownerAvatarUrl: owner?['avatar_url'] as String? ?? '',
      language: json['language'] as String?,
      textMatches: matches,
    );
  }

  static CodeTextMatch _parseTextMatch(Map<String, dynamic> json) {
    final fragment = json['fragment'] as String? ?? '';
    return CodeTextMatch(segments: _parseFragment(fragment));
  }

  /// Splits a text-match fragment on its `<em>` emphasis tags into
  /// plain/highlighted segments.
  static List<CodeFragmentSegment> _parseFragment(String fragment) {
    final segments = <CodeFragmentSegment>[];
    final emphasis = RegExp(r'<em>(.*?)</em>', dotAll: true);
    var cursor = 0;
    for (final match in emphasis.allMatches(fragment)) {
      if (match.start > cursor) {
        segments.add(
          CodeFragmentSegment(text: fragment.substring(cursor, match.start)),
        );
      }
      segments.add(
        CodeFragmentSegment(text: match.group(1) ?? '', highlighted: true),
      );
      cursor = match.end;
    }
    if (cursor < fragment.length) {
      segments.add(CodeFragmentSegment(text: fragment.substring(cursor)));
    }
    return segments;
  }
}
