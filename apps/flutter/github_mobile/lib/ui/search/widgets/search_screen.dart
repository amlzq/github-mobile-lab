import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../view_models/search_viewmodel.dart';
import 'search_section.dart';

/// Search page: input area, history, query suggestions and the combined
/// results preview. The 6-category preview is a state of this same screen
/// (the search bar stays pinned above it), reached on submit/tap.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  /// Whether the combined results preview is shown instead of
  /// history/suggestions.
  var _previewActive = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).updateQuery(value);
  }

  /// Fills the input with [query] (e.g. from a history entry).
  void _applyQuery(String query) {
    _textController
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    ref.read(searchQueryProvider.notifier).updateQuery(query);
    _focusNode.requestFocus();
  }

  /// Back arrow: exits the preview (back to suggestions) or the page.
  void _onBack() {
    if (_previewActive) {
      setState(() => _previewActive = false);
      _focusNode.requestFocus();
      return;
    }
    context.pop();
  }

  /// SEARCH-14: in preview -> collapse to suggestions; non-empty -> clear;
  /// empty -> exit search page.
  void _onClearOrExit() {
    if (_textController.text.isEmpty && !_previewActive) {
      context.pop();
      return;
    }
    _textController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() => _previewActive = false);
    _focusNode.requestFocus();
  }

  /// Enters the combined results preview for [query] (search button / submit).
  void _enterPreview(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _focusNode.unfocus();
    ref.read(searchHistoryProvider.notifier).recordSearch(trimmed);
    setState(() => _previewActive = true);
    ref.read(searchOverviewProvider.notifier).load(trimmed);
  }

  /// Tapping `X with "keywords"` jumps to the category's full results list.
  void _openResults(SearchCategory category, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _focusNode.unfocus();
    ref.read(searchHistoryProvider.notifier).recordSearch(trimmed);
    context.push(
      '${Routes.searchResultsCategory}?q=${Uri.encodeComponent(trimmed)}'
      '&type=${category.name}',
    );
  }

  /// Top-right Refresh: reloads the 6-category preview when active.
  void _onRefresh() {
    if (!_previewActive) return;
    final query = ref.read(searchQueryProvider).trim();
    if (query.isEmpty) return;
    ref.read(searchOverviewProvider.notifier).load(query);
  }

  /// The combined 6-category preview, shown below the pinned search bar.
  Widget _buildPreview(String query) {
    final overview = ref.watch(searchOverviewProvider);
    final categories = SearchOverviewState.displayOrder;
    final dividerColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ListView(
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) Container(height: 8, color: dividerColor),
          SearchSection(
            query: query,
            category: categories[i],
            state:
                overview.sections[categories[i]] ??
                const SearchSectionLoading(),
            onRetry: () =>
                ref.read(searchOverviewProvider.notifier).retry(categories[i]),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final history = ref.watch(searchHistoryProvider);
    final trimmed = query.trim();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: _onBack,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _enterPreview(trimmed),
                      decoration: InputDecoration(
                        hintText: 'Search GitHub',
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _onClearOrExit,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _onRefresh,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _previewActive
                  ? _buildPreview(trimmed)
                  : trimmed.isEmpty
                  ? _buildHistoryBody(history)
                  : ListView(
                      children: [
                        for (final category in SearchCategory.values)
                          ListTile(
                            leading: Icon(category.icon),
                            title: Text(category.suggestionFor(trimmed)),
                            onTap: () => _openResults(category, trimmed),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// P2: empty query shows Recent searches when available,
  /// otherwise the classic empty placeholder.
  Widget _buildHistoryBody(SearchHistoryState history) {
    if (history.isEmpty) return const _SearchEmptyState();

    final historyNotifier = ref.read(searchHistoryProvider.notifier);
    return ListView(
      children: [
        if (history.recent.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent searches',
            actionLabel: 'Clear',
            onAction: historyNotifier.clearRecent,
          ),
          for (final entry in history.recent)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove',
                onPressed: () => historyNotifier.removeRecent(entry),
              ),
              onTap: () => _applyQuery(entry),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// SEARCH-10: empty query placeholder (no history yet).
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Find your stuff.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search all of GitHub for People, Repositories, Organizations, '
              'Issues, and Pull Requests.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

