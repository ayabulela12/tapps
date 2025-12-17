import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistory {
  final String query;
  final DateTime timestamp;

  const SearchHistory({
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static Future<List<SearchHistory>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('search_history') ?? [];
    
    return historyJson.map((item) {
      final Map<String, dynamic> json = jsonDecode(item);
      return SearchHistory.fromJson(json);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addSearchEntry(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    // Remove if exists to avoid duplicates
    history.removeWhere((item) => item.query == query);

    // Add new search to the beginning
    history.insert(
        0, SearchHistory(query: query, timestamp: DateTime.now()));

    // Keep only last 10 searches
    final limitedHistory = history.take(10).toList();

    // Save to SharedPreferences
    await prefs.setStringList(
        'search_history',
        limitedHistory
            .map((item) => jsonEncode(item.toJson()))
            .toList());
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }
}
