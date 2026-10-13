/// REST representation of a user search item (People search).
///
/// The search endpoint returns a limited field set; [name] and [bio] are
/// only populated via the dedicated `/users/{login}` endpoint.
class PeopleApiModel {
  const PeopleApiModel({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.bio,
  });

  final String login;
  final String avatarUrl;
  final String? name;
  final String? bio;

  factory PeopleApiModel.fromJson(Map<String, dynamic> json) {
    return PeopleApiModel(
      login: json['login'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
