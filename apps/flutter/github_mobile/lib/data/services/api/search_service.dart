import 'dart:convert';

import 'package:http/http.dart' as http;

import 'model/code_api_model.dart';
import 'model/issue_api_model.dart';
import 'model/people_api_model.dart';
import 'model/repository_api_model.dart';
import 'model/search_api_model.dart';

/// Thrown when a GitHub search request cannot be completed.
class GitHubSearchException implements Exception {
  const GitHubSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service exposing the GitHub REST search endpoints.
///
/// See https://docs.github.com/rest/search
class GitHubSearchService {
  GitHubSearchService({
    http.Client? client,
    String baseUrl = 'https://api.github.com',
    String? token,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl,
       _token = token;

  final http.Client _client;
  final String _baseUrl;
  final String? _token;

  Map<String, String> _headers({String? accept}) => <String, String>{
    'Accept': accept ?? 'application/vnd.github+json',
    if (_token != null && _token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>?> _getJson(
    Uri uri, {
    required String errorContext,
    bool nullOn404 = false,
    String? accept,
  }) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers(accept: accept));
    } catch (e) {
      throw GitHubSearchException('Network error: $e');
    }

    if (response.statusCode == 404 && nullOn404) return null;
    if (response.statusCode == 401) {
      throw GitHubSearchException(
        '$errorContext failed: authentication required (HTTP 401)',
      );
    }
    if (response.statusCode == 403) {
      throw GitHubSearchException(
        '$errorContext failed: rate limit likely exceeded (HTTP 403)',
      );
    }
    if (response.statusCode != 200) {
      throw GitHubSearchException(
        '$errorContext failed (HTTP ${response.statusCode})',
      );
    }

    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      if (decoded == null) {
        throw const GitHubSearchException('Failed to parse response');
      }
      return decoded;
    } on FormatException {
      throw const GitHubSearchException('Failed to parse response');
    } on TypeError {
      throw const GitHubSearchException('Unexpected response format');
    }
  }

  /// Builds a search query with space-separated qualifiers.
  static String withQualifiers(String query, List<String?> qualifiers) {
    return [
      query,
      ...qualifiers.whereType<String>(),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  /// Searches repositories matching [query].
  ///
  /// [sort] and [order] map to the GitHub `sort`/`order` params; null keeps
  /// the default relevance ranking.
  Future<SearchEnvelopeApiModel<RepositoryApiModel>> searchRepositories(
    String query, {
    int page = 1,
    int perPage = 20,
    String? sort,
    String? order,
  }) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/search/repositories').replace(
        queryParameters: <String, String>{
          'q': query,
          'page': '$page',
          'per_page': '$perPage',
          'sort': ?sort,
          'order': ?order,
        },
      ),
      errorContext: 'Repository search',
    );
    return SearchEnvelopeApiModel.fromJson(json!, RepositoryApiModel.fromJson);
  }

  /// Searches code matching [query].
  ///
  /// GitHub requires authentication for code search; anonymous calls fail
  /// with 401 and surface an explanatory error.
  Future<SearchEnvelopeApiModel<CodeApiModel>> searchCode(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/search/code').replace(
        queryParameters: <String, String>{
          'q': query,
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
      errorContext: 'Code search',
      // Ask GitHub to embed query-match snippets in `text_matches`.
      accept: 'application/vnd.github.text-match+json',
    );
    return SearchEnvelopeApiModel.fromJson(json!, CodeApiModel.fromJson);
  }

  /// Searches Issues ([pullRequests] false) or Pull Requests (true).
  Future<SearchEnvelopeApiModel<IssueApiModel>> searchIssues(
    String query, {
    required bool pullRequests,
    String? state,
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/search/issues').replace(
        queryParameters: <String, String>{
          'q': withQualifiers(query, [
            pullRequests ? 'type:pr' : 'type:issue',
            if (state != null) 'state:$state',
          ]),
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
      errorContext: pullRequests ? 'Pull request search' : 'Issue search',
    );
    return SearchEnvelopeApiModel.fromJson(json!, IssueApiModel.fromJson);
  }

  /// Searches users ([organizations] false) or organizations (true).
  Future<SearchEnvelopeApiModel<T>> searchUsers<T>(
    String query, {
    required bool organizations,
    required T Function(Map<String, dynamic>) parseItem,
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/search/users').replace(
        queryParameters: <String, String>{
          'q': withQualifiers(query, [
            organizations ? 'type:org' : 'type:user',
          ]),
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
      errorContext: organizations ? 'Organization search' : 'People search',
    );
    return SearchEnvelopeApiModel.fromJson(json!, parseItem);
  }

  /// Fetches a single repository, or null when it does not exist.
  Future<RepositoryApiModel?> getRepository(String owner, String repo) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/repos/$owner/$repo'),
      errorContext: 'Repository lookup',
      nullOn404: true,
    );
    if (json == null) return null;
    return RepositoryApiModel.fromJson(json);
  }

  /// Fetches a single user, or null when the login does not exist.
  Future<PeopleApiModel?> getUser(String login) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/users/$login'),
      errorContext: 'User lookup',
      nullOn404: true,
    );
    if (json == null) return null;
    return PeopleApiModel.fromJson(json);
  }
}
