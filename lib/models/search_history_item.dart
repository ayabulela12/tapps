import 'dart:convert';

class SearchHistoryItem {
  final String query;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static List<SearchHistoryItem> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => SearchHistoryItem.fromJson(json))
        .toList();
  }

  static String toJsonList(List<SearchHistoryItem> items) {
    final jsonList = items.map((item) => item.toJson()).toList();
    return json.encode(jsonList);
  }
}
