import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/search_repository.dart';
import '../../../data/services/api/search_service.dart';
import '../../../domain/models/search_result.dart';

/// Resource types the user can search for.
enum SearchCategory {
  code('Code', Icons.code_outlined),
  repositories('Repositories', Icons.book_outlined),
  issues('Issues', Icons.bug_report_outlined),
  pullRequests('Pull Requests', Icons.merge_type_outlined),
  people('People', Icons.person_outlined),
  organizations('Organizations', Icons.group_outlined),
  jumpTo('Jump to', Icons.arrow_outward);

  const SearchCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Resolves a category from its route param name.
  static SearchCategory fromName(String? name) {
    return SearchCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => SearchCategory.repositories,
    );
  }

  /// Suggestion title, e.g. `Repositories with "flutter"`.
  String suggestionFor(String query) {
    if (this == SearchCategory.jumpTo) {
      return 'Jump to "$query"';
    }
    return '$label with "$query"';
  }
}

/// Holds the current search input text.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Optional filters forwarded to the repository layer.
class SearchFilters {
  const SearchFilters({
    this.repoSort = RepoSort.bestMatch,
    this.issueState = IssueStateFilter.all,
  });

  final RepoSort repoSort;
  final IssueStateFilter issueState;
}

/// State of one category section on the combined results page.
sealed class SearchSectionState {
  const SearchSectionState();
}

class SearchSectionLoading extends SearchSectionState {
  const SearchSectionLoading();
}

class SearchSectionSuccess extends SearchSectionState {
  const SearchSectionSuccess(this.outcome);

  final SearchOutcome outcome;
}

class SearchSectionEmpty extends SearchSectionState {
  const SearchSectionEmpty();
}

class SearchSectionError extends SearchSectionState {
  const SearchSectionError(this.message);

  final String message;
}

/// Combined results page: every category loads independently, so one
/// failing section (e.g. code search without authentication) does not
/// break the rest of the page.
class SearchOverviewState {
  const SearchOverviewState({required this.query, required this.sections});

  /// Section display order, mirroring the product design.
  static const List<SearchCategory> displayOrder = [
    SearchCategory.repositories,
    SearchCategory.issues,
    SearchCategory.pullRequests,
    SearchCategory.code,
    SearchCategory.people,
    SearchCategory.organizations,
  ];

  factory SearchOverviewState.initial(String query) => SearchOverviewState(
    query: query,
    sections: {
      for (final category in displayOrder)
        category: const SearchSectionLoading(),
    },
  );

  final String query;
  final Map<SearchCategory, SearchSectionState> sections;
}

/// Fetches a small result set per category for the combined page.
class SearchOverviewViewModel extends Notifier<SearchOverviewState> {
  static const int _itemsPerSection = 3;

  @override
  SearchOverviewState build() => SearchOverviewState.initial('');

  Future<void> load(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    // Already showing this query: keep the loaded sections cached.
    if (state.query == trimmed) return;
    state = SearchOverviewState.initial(trimmed);
    final repository = ref.read(searchRepositoryProvider);
    await Future.wait([
      for (final category in SearchOverviewState.displayOrder)
        _loadCategory(repository, category),
    ]);
  }

  /// Reloads a single failed section.
  Future<void> retry(SearchCategory category) async {
    await _loadCategory(ref.read(searchRepositoryProvider), category);
  }

  Future<void> _loadCategory(
    SearchRepository repository,
    SearchCategory category,
  ) async {
    _setSection(category, const SearchSectionLoading());
    try {
      final SearchOutcome outcome = switch (category) {
        SearchCategory.repositories => await repository.searchRepositories(
          state.query,
          perPage: _itemsPerSection,
        ),
        SearchCategory.issues => await repository.searchIssues(
          state.query,
          pullRequests: false,
          perPage: _itemsPerSection,
        ),
        SearchCategory.pullRequests => await repository.searchIssues(
          state.query,
          pullRequests: true,
          perPage: _itemsPerSection,
        ),
        SearchCategory.code => await repository.searchCode(
          state.query,
          perPage: _itemsPerSection,
        ),
        SearchCategory.people => await repository.searchPeople(
          state.query,
          perPage: _itemsPerSection,
        ),
        SearchCategory.organizations => await repository.searchOrganizations(
          state.query,
          perPage: _itemsPerSection,
        ),
        SearchCategory.jumpTo => throw UnsupportedError('Not a section'),
      };
      _setSection(
        category,
        outcome.isEmpty
            ? const SearchSectionEmpty()
            : SearchSectionSuccess(outcome),
      );
    } on GitHubSearchException catch (e) {
      _setSection(category, SearchSectionError(e.message));
    }
  }

  void _setSection(SearchCategory category, SearchSectionState section) {
    if (!ref.mounted) return;
    state = SearchOverviewState(
      query: state.query,
      sections: {...state.sections, category: section},
    );
  }
}

final searchOverviewProvider =
    NotifierProvider<SearchOverviewViewModel, SearchOverviewState>(
      SearchOverviewViewModel.new,
    );

/// Snapshot of locally persisted search queries.
class SearchHistoryState {
  const SearchHistoryState({this.recent = const []});

  final List<String> recent;

  bool get isEmpty => recent.isEmpty;
}

/// Manages recent searches (auto-recorded on execution).
class SearchHistoryViewModel extends Notifier<SearchHistoryState> {
  @override
  SearchHistoryState build() {
    final repository = ref.watch(searchHistoryRepositoryProvider);
    return SearchHistoryState(recent: repository.recentSearches());
  }

  SearchHistoryRepository get _repository =>
      ref.read(searchHistoryRepositoryProvider);

  Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _repository.addRecent(trimmed);
    state = SearchHistoryState(recent: _repository.recentSearches());
  }

  Future<void> removeRecent(String query) async {
    await _repository.removeRecent(query);
    state = SearchHistoryState(recent: _repository.recentSearches());
  }

  Future<void> clearRecent() async {
    await _repository.clearRecent();
    state = const SearchHistoryState(recent: []);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryViewModel, SearchHistoryState>(
      SearchHistoryViewModel.new,
    );
