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
}
