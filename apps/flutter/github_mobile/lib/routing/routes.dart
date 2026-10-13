/// Route name and path constants for the application.
///
/// Centralizing route paths keeps navigation calls decoupled from the
/// concrete route configuration in [router.dart].
abstract final class Routes {
  /// Root tab: Home feed.
  static const String home = '/';

  /// Root tab: Inbox notifications.
  static const String inbox = '/inbox';

  /// Root tab: Explore
  static const String explore = '/explore';

  /// Root tab: Copilot chat.
  static const String copilot = '/copilot';

  /// Search page (pushed inside a tab branch, bottom nav preserved).
  /// Hosts both the query-suggestion state and the combined 6-category
  /// results preview.
  static const String search = '/search';

  /// Full result list for one category. Params: `q` (query),
  /// `type` (SearchCategory name).
  static const String searchResultsCategory = '/search/results/category';
}
