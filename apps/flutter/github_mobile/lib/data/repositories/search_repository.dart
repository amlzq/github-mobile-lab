import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/code.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/organization.dart';
import '../../domain/models/people.dart';
import '../../domain/models/repository.dart';
import '../../domain/models/search_result.dart';
import '../services/api/model/organization_api_model.dart';
import '../services/api/model/people_api_model.dart';
import '../services/api/model/repository_api_model.dart';
import '../services/api/search_service.dart';
import '../services/shared_preferences_service.dart';

/// Repository-facing abstraction over GitHub search.
class SearchRepository {
  SearchRepository(this._service);

  final GitHubSearchService _service;

  /// Number of profiles hydrated with name/bio per People/Org section.
  static const int _detailLimit = 3;

  static final RegExp _ownerRepoPattern = RegExp(r'^[\w.-]+/[\w.-]+$');

  /// GitHub logins: alphanumeric or single hyphens, max 39 chars.
  static final RegExp _loginPattern = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$',
  );

  Future<RepositoryOutcome> searchRepositories(
    String query, {
    RepoSort sort = RepoSort.bestMatch,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _service.searchRepositories(
      query,
      sort: sort.sortParam,
      order: sort.orderParam,
      page: page,
      perPage: perPage,
    );
    return RepositoryOutcome(
      totalCount: result.totalCount,
      items: result.items.map(_toRepositorySummary).toList(),
    );
  }

  Future<CodeOutcome> searchCode(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _service.searchCode(
      query,
      page: page,
      perPage: perPage,
    );
    return CodeOutcome(
      totalCount: result.totalCount,
      items: result.items
          .map(
            (item) => CodeSummary(
              fileName: item.fileName,
              repoFullName: item.repoFullName,
              path: item.path,
              ownerAvatarUrl: item.ownerAvatarUrl,
              language: item.language,
              textMatches: item.textMatches,
            ),
          )
          .toList(),
    );
  }

  Future<IssueOutcome> searchIssues(
    String query, {
    required bool pullRequests,
    IssueStateFilter stateFilter = IssueStateFilter.all,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _service.searchIssues(
      query,
      pullRequests: pullRequests,
      state: stateFilter.stateParam,
      page: page,
      perPage: perPage,
    );
    return IssueOutcome(
      totalCount: result.totalCount,
      isPullRequests: pullRequests,
      items: result.items
          .map(
            (item) => IssueSummary(
              title: item.title,
              number: item.number,
              state: item.state,
              ownerLogin: item.ownerLogin,
              ownerAvatarUrl: item.ownerAvatarUrl,
              isPullRequest: item.isPullRequest || pullRequests,
              repoFullName: item.repoFullName,
              commentsCount: item.commentsCount,
              createdAt: item.createdAt,
              labels: item.labels,
            ),
          )
          .toList(),
    );
  }

  Future<PeopleOutcome> searchPeople(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _service.searchUsers(
      query,
      organizations: false,
      parseItem: PeopleApiModel.fromJson,
      page: page,
      perPage: perPage,
    );
    final people = result.items
        .map(
          (item) => PersonSummary(login: item.login, avatarUrl: item.avatarUrl),
        )
        .toList();
    return PeopleOutcome(
      totalCount: result.totalCount,
      items: await _hydrateProfiles(people),
    );
  }

  Future<OrganizationOutcome> searchOrganizations(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _service.searchUsers(
      query,
      organizations: true,
      parseItem: OrganizationApiModel.fromJson,
      page: page,
      perPage: perPage,
    );
    final organizations = result.items
        .map(
          (item) =>
              OrganizationSummary(login: item.login, avatarUrl: item.avatarUrl),
        )
        .toList();
    return OrganizationOutcome(
      totalCount: result.totalCount,
      items: await _hydrateOrgProfiles(organizations),
    );
  }

  /// Fetches name/bio for the first [_detailLimit] profiles; the search
  /// endpoint does not return these fields.
  Future<List<PersonSummary>> _hydrateProfiles(List<PersonSummary> people) {
    return Future.wait(
      people.asMap().entries.map((entry) async {
        if (entry.key >= _detailLimit) return entry.value;
        final details = await _fetchProfileDetails(entry.value.login);
        return PersonSummary(
          login: entry.value.login,
          avatarUrl: entry.value.avatarUrl,
          name: details.$1,
          bio: details.$2,
        );
      }),
    );
  }

  Future<List<OrganizationSummary>> _hydrateOrgProfiles(
    List<OrganizationSummary> organizations,
  ) {
    return Future.wait(
      organizations.asMap().entries.map((entry) async {
        if (entry.key >= _detailLimit) return entry.value;
        final details = await _fetchProfileDetails(entry.value.login);
        return OrganizationSummary(
          login: entry.value.login,
          avatarUrl: entry.value.avatarUrl,
          name: details.$1,
          bio: details.$2,
        );
      }),
    );
  }

  Future<(String?, String?)> _fetchProfileDetails(String login) async {
    try {
      final user = await _service.getUser(login);
      return (user?.name, user?.bio);
    } on GitHubSearchException {
      // Profile details are optional decoration; keep the search item.
      return (null, null);
    }
  }

  /// Smarter Jump to (P2):
  /// - `owner/repo` goes straight to that repository;
  /// - a single login-looking token goes straight to that user;
  /// - anything else falls back to a repository search.
  Future<SearchOutcome> jumpTo(String query) async {
    if (_ownerRepoPattern.hasMatch(query)) {
      final parts = query.split('/');
      final repository = await _service.getRepository(parts[0], parts[1]);
      if (repository == null) {
        return const RepositoryOutcome(totalCount: 0, items: []);
      }
      return RepositoryOutcome(
        totalCount: 1,
        items: [_toRepositorySummary(repository)],
      );
    }

    if (_loginPattern.hasMatch(query)) {
      final user = await _service.getUser(query);
      if (user != null) {
        return PeopleOutcome(
          totalCount: 1,
          items: [PersonSummary(login: user.login, avatarUrl: user.avatarUrl)],
        );
      }
    }

    return searchRepositories(query);
  }

  RepositorySummary _toRepositorySummary(RepositoryApiModel item) {
    return RepositorySummary(
      fullName: item.fullName,
      ownerLogin: item.ownerLogin,
      ownerAvatarUrl: item.ownerAvatarUrl,
      stargazersCount: item.stargazersCount,
      description: item.description,
      language: item.language,
    );
  }
}

/// Overridable in tests via [ProviderScope] overrides.
final gitHubSearchServiceProvider = Provider<GitHubSearchService>(
  (ref) => GitHubSearchService(
    token: const bool.hasEnvironment('GITHUB_TOKEN')
        ? const String.fromEnvironment('GITHUB_TOKEN')
        : null,
  ),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(gitHubSearchServiceProvider)),
);

/// Persists recent search queries (P2: Search History / Recent Searches).
class SearchHistoryRepository {
  const SearchHistoryRepository(this._prefs);

  final SharedPreferencesService _prefs;

  static const String _recentKey = 'search.recent_queries';

  /// Most recent first, capped to [_maxRecent], deduplicated.
  static const int _maxRecent = 10;

  List<String> recentSearches() => _prefs.readStrings(_recentKey);

  Future<void> addRecent(String query) {
    final trimmed = query.trim();
    final current = recentSearches()..remove(trimmed);
    current.insert(0, trimmed);
    return _prefs.writeStrings(_recentKey, current.take(_maxRecent).toList());
  }

  Future<void> removeRecent(String query) {
    final current = recentSearches()..remove(query);
    return _prefs.writeStrings(_recentKey, current);
  }

  Future<void> clearRecent() => _prefs.writeStrings(_recentKey, const []);
}

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>(
  (ref) => SearchHistoryRepository(ref.watch(sharedPreferencesServiceProvider)),
);
