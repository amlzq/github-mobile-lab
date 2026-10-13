/// Application-facing summary of a GitHub organization.
class OrganizationSummary {
  const OrganizationSummary({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.bio,
  });

  final String login;

  final String avatarUrl;

  /// Display name from the org profile, when available.
  final String? name;

  /// Profile description, when available.
  final String? bio;

  String get displayName => (name == null || name!.isEmpty) ? login : name!;
}
