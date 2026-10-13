import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';

/// Home tab: activity feed of followed repositories.
///
/// Page content is a blank placeholder for now; the app bar exposes the
/// search entry point.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
      // TODO(home): replace with the real Home feature content.
      body: const Center(child: Text('Home Page')),
    );
  }
}
