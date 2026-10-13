/// Application-facing summary of a GitHub repository.
///
/// Represents only the fields the search UI needs, decoupled from the
/// GitHub REST response shape.
class RepositorySummary {
  const RepositorySummary({
    required this.fullName,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.stargazersCount,
    this.description,
    this.language,
  });

  /// Full name in `owner/repo` form, e.g. `flutter/flutter`.
  final String fullName;

  final String ownerLogin;

  final String ownerAvatarUrl;

  final int stargazersCount;

  final String? description;

  final String? language;
}
