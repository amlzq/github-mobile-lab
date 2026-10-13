/// A label attached to an Issue or Pull Request.
class IssueLabel {
  const IssueLabel({required this.name, required this.colorHex});

  final String name;

  /// Label color as 6-digit hex without `#`, e.g. `d4c5f9`.
  final String colorHex;
}

/// Application-facing summary of an Issue or Pull Request.
///
/// Issues and Pull Requests share the GitHub search endpoint; [isPullRequest]
/// distinguishes them.
class IssueSummary {
  const IssueSummary({
    required this.title,
    required this.number,
    required this.state,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.isPullRequest,
    this.repoFullName,
    this.commentsCount = 0,
    this.createdAt,
    this.labels = const [],
  });

  final String title;

  final int number;

  /// `open` or `closed`.
  final String state;

  /// Repository the item belongs to, in `owner/repo` form, when known.
  final String? repoFullName;

  final String ownerLogin;

  final String ownerAvatarUrl;

  final bool isPullRequest;

  final int commentsCount;

  final DateTime? createdAt;

  final List<IssueLabel> labels;

  String get stateLabel =>
      state.isEmpty ? state : state[0].toUpperCase() + state.substring(1);
}
