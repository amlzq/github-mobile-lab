/// REST representation of an organization search item.
class OrganizationApiModel {
  const OrganizationApiModel({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.bio,
  });

  final String login;
  final String avatarUrl;
  final String? name;
  final String? bio;

  factory OrganizationApiModel.fromJson(Map<String, dynamic> json) {
    return OrganizationApiModel(
      login: json['login'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
