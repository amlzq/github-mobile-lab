import '../../../../domain/models/issue.dart';

/// REST representation of an Issue / Pull Request search item.
class IssueApiModel {
  const IssueApiModel({
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
  final String state;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final bool isPullRequest;

  /// `owner/repo`, extracted from the API `repository_url`, when present.
  final String? repoFullName;

  final int commentsCount;
  final DateTime? createdAt;
  final List<IssueLabel> labels;

  factory IssueApiModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final labels = ((json['labels'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (label) => IssueLabel(
            name: label['name'] as String? ?? '',
            colorHex: (label['color'] as String? ?? '').replaceAll('#', ''),
          ),
        )
        .where((label) => label.name.isNotEmpty)
        .toList();
    return IssueApiModel(
      title: json['title'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      state: json['state'] as String? ?? '',
      ownerLogin: user?['login'] as String? ?? '',
      ownerAvatarUrl: user?['avatar_url'] as String? ?? '',
      isPullRequest: json['pull_request'] != null,
      repoFullName: _repoFullNameFromApiUrl(json['repository_url'] as String?),
      commentsCount: json['comments'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      labels: labels,
    );
  }

  static String? _repoFullNameFromApiUrl(String? url) {
    if (url == null) return null;
    const marker = '/repos/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    return url.substring(index + marker.length);
  }
}
