import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/search_result.dart';
import '../../../routing/routes.dart';
import '../../../utils/formatting.dart';
import '../view_models/search_viewmodel.dart';
import 'code_list_item.dart';
import 'issue_list_item.dart';
import 'org_list_item.dart';
import 'people_list_item.dart';
import 'repo_list_item.dart';

/// A single category block on the combined results page: title, up to three
/// result rows and a `See N more X` footer linking to the full list.
class SearchSection extends StatelessWidget {
  const SearchSection({
    super.key,
    required this.query,
    required this.category,
    required this.state,
    required this.onRetry,
  });

  /// The search query, used to build the full-list deep link.
  final String query;

  final SearchCategory category;
  final SearchSectionState state;
  final VoidCallback onRetry;

  /// Footer noun, e.g. `code results`, `pull requests`.
  String get _moreNoun => switch (category) {
    SearchCategory.code => 'code results',
    SearchCategory.repositories => 'repositories',
    SearchCategory.issues => 'issues',
    SearchCategory.pullRequests => 'pull requests',
    SearchCategory.people => 'people',
    SearchCategory.organizations => 'organizations',
    SearchCategory.jumpTo => 'results',
  };

  Widget _itemFor(int index, SearchOutcome outcome) => switch (outcome) {
    RepositoryOutcome(:final items) => RepoListItem(repository: items[index]),
    CodeOutcome(:final items) => CodeListItem(item: items[index]),
    IssueOutcome(:final items) => IssueListItem(item: items[index]),
    PeopleOutcome(:final items) => PeopleListItem(person: items[index]),
    OrganizationOutcome(:final items) => OrgListItem(
      organization: items[index],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (state) {
      SearchSectionLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      // Empty sections are hidden entirely, like on GitHub mobile.
      SearchSectionEmpty() => const SizedBox.shrink(),
      SearchSectionError() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Couldn\'t load $_moreNoun',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      SearchSectionSuccess(:final outcome) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              category.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (var i = 0; i < outcome.itemCount; i++) _itemFor(i, outcome),
          _SeeMoreFooter(
            visible: outcome.totalCount > outcome.itemCount,
            label:
                'See ${formatCompactCount(outcome.totalCount - outcome.itemCount)} '
                'more $_moreNoun',
            onTap: () => context.push(
              '${Routes.searchResultsCategory}'
              '?q=${Uri.encodeComponent(query)}&type=${category.name}',
            ),
          ),
        ],
      ),
    };
  }
}

class _SeeMoreFooter extends StatelessWidget {
  const _SeeMoreFooter({
    required this.visible,
    required this.label,
    required this.onTap,
  });

  final bool visible;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
