import 'code.dart';
import 'issue.dart';
import 'organization.dart';
import 'people.dart';
import 'repository.dart';

/// Sort options for repository search results.
enum RepoSort {
  bestMatch('Best match', null, null),
  mostStars('Most stars', 'stars', 'desc'),
  fewestStars('Fewest stars', 'stars', 'asc'),
  recentlyUpdated('Recently updated', 'updated', 'desc');

  const RepoSort(this.label, this.sortParam, this.orderParam);

  final String label;

  /// GitHub `sort` query param; null keeps GitHub's relevance ranking.
  final String? sortParam;

  /// GitHub `order` query param; null uses the default.
  final String? orderParam;
}

/// Open/closed filter for Issue and Pull Request searches.
enum IssueStateFilter {
  all('All', null),
  open('Open', 'open'),
  closed('Closed', 'closed');

  const IssueStateFilter(this.label, this.stateParam);

  final String label;

  /// Qualifier value appended to the query; null means no filter.
  final String? stateParam;
}

/// Unified search outcome across resource types.
///
/// Every category produces one of these, so the result UI can treat
/// Loading / Empty / Error / list rendering uniformly (P1: unified result
/// experience).
sealed class SearchOutcome {
  const SearchOutcome({required this.totalCount});

  /// Total matches reported by GitHub.
  final int totalCount;

  int get itemCount;

  bool get isEmpty => itemCount == 0;
}

class RepositoryOutcome extends SearchOutcome {
  const RepositoryOutcome({required super.totalCount, required this.items});

  final List<RepositorySummary> items;

  @override
  int get itemCount => items.length;
}

class CodeOutcome extends SearchOutcome {
  const CodeOutcome({required super.totalCount, required this.items});

  final List<CodeSummary> items;

  @override
  int get itemCount => items.length;
}

class IssueOutcome extends SearchOutcome {
  const IssueOutcome({
    required super.totalCount,
    required this.items,
    required this.isPullRequests,
  });

  final List<IssueSummary> items;

  final bool isPullRequests;

  @override
  int get itemCount => items.length;
}

class PeopleOutcome extends SearchOutcome {
  const PeopleOutcome({required super.totalCount, required this.items});

  final List<PersonSummary> items;

  @override
  int get itemCount => items.length;
}

class OrganizationOutcome extends SearchOutcome {
  const OrganizationOutcome({required super.totalCount, required this.items});

  final List<OrganizationSummary> items;

  @override
  int get itemCount => items.length;
}
