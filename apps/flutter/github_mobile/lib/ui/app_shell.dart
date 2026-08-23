import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root shell of the app: hosts the tab page content and the bottom
/// navigation bar with four items (Home / Inbox / Explore / Copilot).
///
/// The [navigationShell] comes from a [StatefulShellRoute.indexedStack],
/// which preserves each tab's navigation state independently.
/// Tapping the already-selected tab returns that branch to its root.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            // Pop the current branch to its root when re-tapped.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Copilot',
          ),
        ],
      ),
    );
  }
}
