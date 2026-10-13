import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] so upper layers stay testable.
class SharedPreferencesService {
  const SharedPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  List<String> readStrings(String key) => _prefs.getStringList(key) ?? [];

  Future<void> writeStrings(String key, List<String> value) =>
      _prefs.setStringList(key, value);
}

/// Must be overridden in the root [ProviderScope] with an instance built
/// from an initialized [SharedPreferences].
final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesServiceProvider must be overridden in bootstrap',
  ),
);
