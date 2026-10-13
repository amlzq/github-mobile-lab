import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/search_result.dart';
import '../view_models/category_result_viewmodel.dart';
import '../view_models/search_viewmodel.dart';
import 'code_list_item.dart';
import 'issue_list_item.dart';
import 'org_list_item.dart';
import 'people_list_item.dart';
import 'repo_list_item.dart';

/// Full result list for a single category, reached from the combined page's
/// `See N more` footer. Keeps the category-specific filter bars and loads
/// results page by page via its own [CategoryResultViewModel].
class SearchResultsCategoryScreen extends ConsumerStatefulWidget {
  const SearchResultsCategoryScreen({
    super.key,
    required this.query,
    required this.category,
  });

  final String query;
  final SearchCategory category;

  @override
  ConsumerState<SearchResultsCategoryScreen> createState() =>
      _SearchResultsCategoryScreenState();
}

class _SearchResultsCategoryScreenState
    extends ConsumerState<SearchResultsCategoryScreen> {
  RepoSort _repoSort = RepoSort.bestMatch;
  IssueStateFilter _issueState = IssueStateFilter.all;

  final ScrollController _scrollController = ScrollController();

  ({String query, SearchCategory category}) get _args =>
      (query: widget.query, category: widget.category);

  CategoryResultViewModel get _notifier =>
      ref.read(categoryResultProvider(_args).notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifier.loadInitial());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _notifier.loadMore();
    }
  }

  void _applyFilters() {
    _notifier.setFilters(
      SearchFilters(repoSort: _repoSort, issueState: _issueState),
    );
  }

  bool get _isRepoLike =>
      widget.category == SearchCategory.repositories ||
      widget.category == SearchCategory.jumpTo;

  bool get _isIssueLike =>
      widget.category == SearchCategory.issues ||
      widget.category == SearchCategory.pullRequests;

  PreferredSizeWidget? _buildFilterBar() {
    if (_isRepoLike) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<RepoSort>(
            initialValue: _repoSort,
            onSelected: (value) {
              setState(() => _repoSort = value);
              _applyFilters();
            },
            itemBuilder: (_) => [
              for (final sort in RepoSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 6),
                  Text('Sort: ${_repoSort.label}'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_isIssueLike) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final filter in IssueStateFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: _issueState == filter,
                    onSelected: (_) {
                      setState(() => _issueState = filter);
                      _applyFilters();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  Widget _itemFor(int index, SearchOutcome results) => switch (results) {
    RepositoryOutcome(:final items) => RepoListItem(repository: items[index]),
    CodeOutcome(:final items) => CodeListItem(item: items[index]),
    IssueOutcome(:final items) => IssueListItem(item: items[index]),
    PeopleOutcome(:final items) => PeopleListItem(person: items[index]),
    OrganizationOutcome(:final items) => OrgListItem(
      organization: items[index],
    ),
  };

  Widget _buildFooter(CategoryResultState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _notifier.loadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No more results',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: FilledButton.tonal(
          onPressed: _notifier.loadMore,
          child: const Text('Load more'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryResultProvider(_args));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.suggestionFor(widget.query),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _buildFilterBar(),
      ),
      body: switch (state.status) {
        CategoryResultStatus.initial || CategoryResultStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        CategoryResultStatus.empty => _MessageView(
          icon: Icons.search_off,
          title: 'No results found',
          message:
              'We couldn\'t find anything for "${widget.query}". '
              'Try different keywords.',
        ),
        CategoryResultStatus.error => _MessageView(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          message: state.errorMessage ?? 'Unknown error',
          action: FilledButton.tonalIcon(
            onPressed: _notifier.loadInitial,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
        CategoryResultStatus.success when state.outcome != null =>
          RefreshIndicator(
            onRefresh: _notifier.refresh,
            child: ListView.separated(
              controller: _scrollController,
              itemCount: state.outcome!.itemCount + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.outcome!.itemCount) {
                  return _buildFooter(state);
                }
                return _itemFor(index, state.outcome!);
              },
            ),
          ),
        CategoryResultStatus.success => const SizedBox.shrink(),
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
