/// REST representation of a GitHub repository (search item).
class RepositoryApiModel {
  const RepositoryApiModel({
    required this.fullName,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.stargazersCount,
    this.description,
    this.language,
  });

  final String fullName;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final int stargazersCount;
  final String? description;
  final String? language;

  factory RepositoryApiModel.fromJson(Map<String, dynamic> json) {
    return RepositoryApiModel(
      fullName: json['full_name'] as String? ?? '',
      ownerLogin:
          (json['owner'] as Map<String, dynamic>?)?['login'] as String? ?? '',
      ownerAvatarUrl:
          (json['owner'] as Map<String, dynamic>?)?['avatar_url'] as String? ??
          '',
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      description: json['description'] as String?,
      language: json['language'] as String?,
    );
  }
}
