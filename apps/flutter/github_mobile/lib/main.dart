import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/shared_preferences_service.dart';
import 'routing/router.dart';
import 'ui/core/themes/theme.dart';

/// Shared application bootstrap, invoked by every entrypoint
/// (`main.dart`, `main_development.dart`, `main_staging.dart`).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesServiceProvider.overrideWithValue(
          SharedPreferencesService(prefs),
        ),
      ],
      child: const GithubMobileApp(),
    ),
  );
}

/// Root widget of the GitHub Mobile app.
class GithubMobileApp extends ConsumerWidget {
  const GithubMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GitHub Mobile',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() => bootstrap();
