import 'package:flutter/foundation.dart';

class ProvinceRecordException implements Exception {
  final String message;
  final dynamic originalError;

  ProvinceRecordException(this.message, [this.originalError]);

  @override
  String toString() =>
      'ProvinceRecordException: $message'
      '${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

class ProvinceRecord {
  final double thisWeekLevel;
  final double lastWeekLevel;
  final double lastYearLevel;
  final DateTime timestamp;

  ProvinceRecord({
    required this.thisWeekLevel,
    required this.lastWeekLevel,
    required this.lastYearLevel,
    required this.timestamp,
  }) {
    // Values are clamped by the Supabase service before reaching here,
    // but we keep a soft validation with a warning instead of throwing.
    void warnIfOutOfRange(double v, String name) {
      if (v < 0 || v > 100) {
        debugPrint('⚠️ ProvinceRecord: $name=$v is outside 0–100 (clamped upstream)');
      }
    }

    warnIfOutOfRange(thisWeekLevel, 'thisWeekLevel');
    warnIfOutOfRange(lastWeekLevel, 'lastWeekLevel');
    warnIfOutOfRange(lastYearLevel, 'lastYearLevel');
  }

  /// Build directly from a plain Dart map (Supabase / computed totals).
  factory ProvinceRecord.fromMap(Map<String, dynamic> map) {
    double parse(dynamic v, String name) {
      if (v == null) {
        debugPrint('⚠️ ProvinceRecord.fromMap: missing $name, defaulting to 0.0');
        return 0.0;
      }
      try {
        return (v as num).toDouble();
      } catch (e) {
        throw ProvinceRecordException('Invalid $name value: $v', e);
      }
    }

    DateTime parseTimestamp(dynamic v) {
      if (v == null) return DateTime.now().subtract(const Duration(days: 1));
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now().subtract(const Duration(days: 1));
      }
    }

    return ProvinceRecord(
      thisWeekLevel: parse(map['thisWeekLevel'] ?? map['this_week_level'], 'thisWeekLevel'),
      lastWeekLevel: parse(map['lastWeekLevel'] ?? map['last_week_level'], 'lastWeekLevel'),
      lastYearLevel: parse(map['lastYearLevel'] ?? map['last_year_level'], 'lastYearLevel'),
      timestamp: parseTimestamp(map['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'this_week_level': thisWeekLevel,
        'last_week_level': lastWeekLevel,
        'last_year_level': lastYearLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'ProvinceRecord(thisWeek: $thisWeekLevel%, '
      'lastWeek: $lastWeekLevel%, lastYear: $lastYearLevel%, '
      'timestamp: $timestamp)';
}
