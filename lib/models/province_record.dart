import 'package:flutter/foundation.dart';

class ProvinceRecordException implements Exception {
  final String message;
  final dynamic originalError;

  ProvinceRecordException(this.message, [this.originalError]);

  @override
  String toString() => 'ProvinceRecordException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
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
    // Validate water levels are within reasonable bounds (0-100%)
    if (thisWeekLevel < 0 || thisWeekLevel > 100) {
      throw ProvinceRecordException('Invalid this week level: $thisWeekLevel. Must be between 0 and 100');
    }
    if (lastWeekLevel < 0 || lastWeekLevel > 100) {
      throw ProvinceRecordException('Invalid last week level: $lastWeekLevel. Must be between 0 and 100');
    }
    if (lastYearLevel < 0 || lastYearLevel > 100) {
      throw ProvinceRecordException('Invalid last year level: $lastYearLevel. Must be between 0 and 100');
    }

    // Validate timestamp is not in the future
    if (timestamp.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw ProvinceRecordException('Invalid timestamp: $timestamp. Cannot be in the future');
    }
  }

  factory ProvinceRecord.fromMap(Map<String, dynamic> data) {
    try {
      double parseDouble(dynamic value, String fieldName) {
        if (value == null) {
          debugPrint('⚠️ Missing $fieldName, defaulting to 0.0');
          return 0.0;
        }
        try {
          return (value is int) ? value.toDouble() : (value as num).toDouble();
        } catch (e) {
          debugPrint('❌ Error parsing $fieldName: $value');
          throw ProvinceRecordException('Invalid $fieldName value: $value', e);
        }
      }

      final timestampRaw = data['timestamp'];
      final timestamp = timestampRaw is String
          ? (DateTime.tryParse(timestampRaw) ??
              DateTime.now().subtract(const Duration(days: 1)))
          : DateTime.now().subtract(const Duration(days: 1));
      
      return ProvinceRecord(
        thisWeekLevel: parseDouble(data['this_week_level'], 'this_week_level'),
        lastWeekLevel: parseDouble(data['last_week_level'], 'last_week_level'),
        lastYearLevel: parseDouble(data['last_year_level'], 'last_year_level'),
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('❌ Error parsing province record: $e');
      throw ProvinceRecordException('Failed to parse document data', e);
    }
  }

  Map<String, dynamic> toJson() => {
    'this_week_level': thisWeekLevel,
    'last_week_level': lastWeekLevel,
    'last_year_level': lastYearLevel,
    'timestamp': timestamp.toIso8601String(),  // Changed from Timestamp.fromDate
  };

  @override
  String toString() => 'ProvinceRecord(thisWeekLevel: $thisWeekLevel%, lastWeekLevel: $lastWeekLevel%, lastYearLevel: $lastYearLevel%, timestamp: $timestamp)';
}
