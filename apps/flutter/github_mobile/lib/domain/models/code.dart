/// A highlighted (or plain) segment inside a code text match.
class CodeFragmentSegment {
  const CodeFragmentSegment({required this.text, this.highlighted = false});

  final String text;

  /// Whether this segment matched the query and should be emphasized.
  final bool highlighted;
}

/// One `text_matches` entry of a code search hit.
class CodeTextMatch {
  const CodeTextMatch({required this.segments});

  final List<CodeFragmentSegment> segments;
}

/// Application-facing summary of a code search hit.
class CodeSummary {
  const CodeSummary({
    required this.fileName,
    required this.repoFullName,
    required this.path,
    required this.ownerAvatarUrl,
    this.language,
    this.textMatches = const [],
  });

  final String fileName;

  /// Repository containing the file, in `owner/repo` form.
  final String repoFullName;

  /// Path of the file inside the repository.
  final String path;

  final String ownerAvatarUrl;

  /// GitHub-reported language of the file, when known.
  final String? language;

  /// Snippets with query match highlighting, empty when the API returned
  /// no text matches (e.g. missing the text-match media type).
  final List<CodeTextMatch> textMatches;
}
