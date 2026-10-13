/// Application-facing summary of a GitHub user found via People search.
class PersonSummary {
  const PersonSummary({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.bio,
  });

  final String login;

  final String avatarUrl;

  /// Display name from the user profile, when available.
  final String? name;

  /// Profile bio, when available.
  final String? bio;

  String get displayName => (name == null || name!.isEmpty) ? login : name!;
}
