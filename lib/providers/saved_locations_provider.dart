import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLocationsNotifier extends StateNotifier<List<String>> {
  SavedLocationsNotifier() : super([]) {
    _loadSavedLocations();
  }

  static const _key = 'saved_locations';

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocations = prefs.getStringList(_key) ?? [];
    state = savedLocations;
  }

  Future<void> addLocation(String location) async {
    if (!state.contains(location)) {
      final updatedLocations = [...state, location];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, updatedLocations);
      state = updatedLocations;
    }
  }

  Future<void> removeLocation(String location) async {
    final updatedLocations = state.where((l) => l != location).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updatedLocations);
    state = updatedLocations;
  }
}

final savedLocationsProvider =
    StateNotifierProvider<SavedLocationsNotifier, List<String>>(
  (ref) => SavedLocationsNotifier(),
);
