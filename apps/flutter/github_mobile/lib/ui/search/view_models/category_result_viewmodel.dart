import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/search_repository.dart';
import '../../../data/services/api/search_service.dart';
import '../../../domain/models/search_result.dart';
import 'search_viewmodel.dart';

/// Lifecycle of a paginated category result screen.
enum CategoryResultStatus { initial, loading, success, empty, error }

/// State for [SearchResultsCategoryScreen]. Holds the accumulated result list
/// and the pagination cursor so the screen can load more pages on demand.
class CategoryResultState {
  const CategoryResultState({
    this.status = CategoryResultStatus.initial,
    required this.query,
    required this.category,
    this.filters = const SearchFilters(),
    this.outcome,
    this.page = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final CategoryResultStatus status;
  final String query;
  final SearchCategory category;
  final SearchFilters filters;
  final SearchOutcome? outcome;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  CategoryResultState copyWith({
    CategoryResultStatus? status,
    SearchFilters? filters,
    SearchOutcome? outcome,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryResultState(
      status: status ?? this.status,
      query: query,
      category: category,
      filters: filters ?? this.filters,
      outcome: outcome ?? this.outcome,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Dedicated, per-screen ViewModel for [SearchResultsCategoryScreen].
///
/// Keyed by `(query, category)` via a Riverpod family, so each screen instance
/// owns its own state. [loadInitial] fetches the first page; [loadMore] appends
/// subsequent pages to the accumulated [CategoryResultState.outcome].
class CategoryResultViewModel extends Notifier<CategoryResultState> {
  CategoryResultViewModel(this.query, this.category);

  final String query;
  final SearchCategory category;

  static const int _pageSize = 20;

  @override
  CategoryResultState build() =>
      CategoryResultState(query: query, category: category);

  SearchRepository get _repository => ref.read(searchRepositoryProvider);

  Future<SearchOutcome> _fetchPage(int page) {
    final f = state.filters;
    return switch (category) {
      SearchCategory.code => _repository.searchCode(
        query,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.repositories => _repository.searchRepositories(
        query,
        sort: f.repoSort,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.issues => _repository.searchIssues(
        query,
        pullRequests: false,
        stateFilter: f.issueState,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.pullRequests => _repository.searchIssues(
        query,
        pullRequests: true,
        stateFilter: f.issueState,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.people => _repository.searchPeople(
        query,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.organizations => _repository.searchOrganizations(
        query,
        page: page,
        perPage: _pageSize,
      ),
      SearchCategory.jumpTo => throw UnsupportedError(
        'jumpTo is not a paginated list',
      ),
    };
  }

  /// Appends [incoming] onto [existing]; both are the same category outcome.
  SearchOutcome _merge(SearchOutcome existing, SearchOutcome incoming) {
    final totalCount = incoming.totalCount;
    return switch (existing) {
      RepositoryOutcome(:final items) when incoming is RepositoryOutcome =>
        RepositoryOutcome(
          totalCount: totalCount,
          items: [...items, ...incoming.items],
        ),
      CodeOutcome(:final items) when incoming is CodeOutcome =>
        CodeOutcome(totalCount: totalCount, items: [...items, ...incoming.items]),
      IssueOutcome(:final items, :final isPullRequests)
          when incoming is IssueOutcome =>
        IssueOutcome(
          totalCount: totalCount,
          items: [...items, ...incoming.items],
          isPullRequests: isPullRequests,
        ),
      PeopleOutcome(:final items) when incoming is PeopleOutcome =>
        PeopleOutcome(
          totalCount: totalCount,
          items: [...items, ...incoming.items],
        ),
      OrganizationOutcome(:final items) when incoming is OrganizationOutcome =>
        OrganizationOutcome(
          totalCount: totalCount,
          items: [...items, ...incoming.items],
        ),
      _ => incoming,
    };
  }

  /// Loads (or reloads) the first page.
  Future<void> loadInitial() async {
    if (state.status == CategoryResultStatus.loading) return;
    state = state.copyWith(
      status: CategoryResultStatus.loading,
      outcome: null,
      page: 0,
      hasMore: true,
      clearError: true,
    );
    try {
      final outcome = await _fetchPage(1);
      state = state.copyWith(
        status: outcome.isEmpty
            ? CategoryResultStatus.empty
            : CategoryResultStatus.success,
        outcome: outcome,
        page: 1,
        hasMore: outcome.totalCount > _pageSize,
      );
    } on GitHubSearchException catch (e) {
      state = state.copyWith(
        status: CategoryResultStatus.error,
        errorMessage: e.message,
      );
    }
  }

  /// Appends the next page to the accumulated list.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.outcome == null) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final incoming = await _fetchPage(nextPage);
      final merged = _merge(state.outcome!, incoming);
      state = state.copyWith(
        status: CategoryResultStatus.success,
        outcome: merged,
        page: nextPage,
        isLoadingMore: false,
        hasMore: merged.totalCount > nextPage * _pageSize,
      );
    } on GitHubSearchException catch (e) {
      // Keep the loaded list; surface the failure in the footer instead.
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
      );
    }
  }

  /// Pull-to-refresh / retry alias for [loadInitial].
  Future<void> refresh() => loadInitial();

  /// Applies new filters and restarts pagination from the first page.
  void setFilters(SearchFilters filters) {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters);
    loadInitial();
  }
}

final categoryResultProvider = NotifierProvider.family<
  CategoryResultViewModel,
  CategoryResultState,
  ({String query, SearchCategory category})
>((arg) => CategoryResultViewModel(arg.query, arg.category));
