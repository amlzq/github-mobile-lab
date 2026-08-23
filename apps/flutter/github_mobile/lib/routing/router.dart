import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/app_shell.dart';
import '../ui/copilot/widgets/copilot_screen.dart';
import '../ui/explore/widgets/explore_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/inbox/widgets/inbox_screen.dart';
import 'routes.dart';

/// Application router.
///
/// The four bottom-navigation tabs are modeled as branches of a
/// [StatefulShellRoute.indexedStack], so each tab keeps its own navigation
/// stack and state while switching between tabs.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inbox,
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.copilot,
                builder: (context, state) => const CopilotScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
