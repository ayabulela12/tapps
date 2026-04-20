import 'package:appmaniazar/models/province_record.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DamRecord {
  final String id;
  final String name;
  final String region;
  final double thisWeekLevel;
  final double lastWeekLevel;
  final double lastYearLevel;
  final String risk;
  final DateTime created_at;

  DamRecord({
    required this.id,
    required this.name,
    required this.region,
    required this.thisWeekLevel,
    required this.lastWeekLevel,
    required this.lastYearLevel,
    required this.risk,
    required this.created_at,
  });

  factory DamRecord.fromMap(Map<String, dynamic> map) {
    final level = (map['level'] as num?)?.toDouble() ?? 0.0;
    final weeklyChange = (map['weekly_change'] as num?)?.toDouble() ?? 0.0;
    final yearlyChange = (map['yearly_change'] as num?)?.toDouble() ?? 0.0;

    final rawId = map['id'];
    final rawTimestamp = map['created_at'];

    return DamRecord(
      id: rawId?.toString() ?? '',
      name: map['dam'] as String? ?? 'Unknown Dam',
      region: map['region'] as String? ?? '',
      thisWeekLevel: level,
      lastWeekLevel: level - weeklyChange,
      lastYearLevel: level - yearlyChange,
      risk: map['risk'] as String? ?? '',
      created_at: rawTimestamp is String
          ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toScreenMap() => {
        'id': id,
        'name': name,
        'this_week_level': thisWeekLevel,
        'last_week_level': lastWeekLevel,
        'last_year_level': lastYearLevel,
        'risk': risk,
        'location': region,
        'capacity': 'N/A',
      };
}

const Map<String, String> _codeToRegion = {
  'WC': 'Western Cape',
  'EC': 'Eastern Cape',
  'NC': 'Northern Cape',
  'FS': 'Free State',
  'KZN': 'KwaZulu-Natal',
  'GP': 'Gauteng',
  'MP': 'Mpumalanga',
  'LP': 'Limpopo',
  'NW': 'North West',
};

String _regionForCode(String code) => _codeToRegion[code.toUpperCase()] ?? code;

class SupabaseDamService {
  final SupabaseClient _client;
  static const String _damTable = 'dam_levels';

  SupabaseDamService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  double _clampPercent(double value) => value.clamp(0.0, 100.0);

  List<Map<String, dynamic>> _dedupe(List<Map<String, dynamic>> rows) {
    final seen = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key = (row['dam'] as String? ?? '').trim().toLowerCase();
      if (!seen.containsKey(key)) {
        seen[key] = row;
      } else {
        final existing =
            DateTime.tryParse(seen[key]!['created_at'] as String? ?? '') ??
                DateTime(0);
        final current = DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime(0);
        if (current.isAfter(existing)) {
          seen[key] = row;
        }
      }
    }
    return seen.values.toList();
  }

  Future<List<DamRecord>> getAllDams() async {
    try {
      final rows = await _client
          .from(_damTable)
          .select()
          .order('created_at', ascending: false);

      final deduped = _dedupe(List<Map<String, dynamic>>.from(rows as List));
      debugPrint('✅ Supabase: fetched ${deduped.length} unique dams');
      return deduped.map(DamRecord.fromMap).toList();
    } catch (e) {
      debugPrint('❌ Supabase getAllDams error: $e');
      rethrow;
    }
  }

  Future<List<DamRecord>> getDamsByRegion(String provinceCode) async {
    final regionName = _regionForCode(provinceCode);
    try {
      final rows = await _client
          .from(_damTable)
          .select()
          .eq('region', regionName)
          .order('created_at', ascending: false);

      final deduped = _dedupe(List<Map<String, dynamic>>.from(rows as List));
      debugPrint('✅ Supabase: fetched ${deduped.length} dams for $regionName');
      return deduped.map(DamRecord.fromMap).toList();
    } catch (e) {
      debugPrint('❌ Supabase getDamsByRegion($provinceCode) error: $e');
      rethrow;
    }
  }

  Future<
      ({
        double thisWeek,
        double lastWeek,
        double lastYear,
        DateTime timestamp
      })> getNationalTotals() async {
    final dams = await getAllDams();
    if (dams.isEmpty) {
      return (
        thisWeek: 0.0,
        lastWeek: 0.0,
        lastYear: 0.0,
        timestamp: DateTime.now(),
      );
    }

    final thisWeek =
        dams.map((d) => d.thisWeekLevel).reduce((a, b) => a + b) / dams.length;
    final lastWeek =
        dams.map((d) => d.lastWeekLevel).reduce((a, b) => a + b) / dams.length;
    final lastYear =
        dams.map((d) => d.lastYearLevel).reduce((a, b) => a + b) / dams.length;
    final latest =
        dams.map((d) => d.created_at).reduce((a, b) => a.isAfter(b) ? a : b);

    return (
      thisWeek: _clampPercent(thisWeek),
      lastWeek: _clampPercent(lastWeek),
      lastYear: _clampPercent(lastYear),
      timestamp: latest,
    );
  }

  Future<ProvinceRecord> getProvinceTotals(String provinceCode) async {
    final dams = await getDamsByRegion(provinceCode);
    if (dams.isEmpty) {
      return ProvinceRecord(
        thisWeekLevel: 0,
        lastWeekLevel: 0,
        lastYearLevel: 0,
        timestamp: DateTime.now(),
      );
    }

    final thisWeek =
        dams.map((d) => d.thisWeekLevel).reduce((a, b) => a + b) / dams.length;
    final lastWeek =
        dams.map((d) => d.lastWeekLevel).reduce((a, b) => a + b) / dams.length;
    final lastYear =
        dams.map((d) => d.lastYearLevel).reduce((a, b) => a + b) / dams.length;
    final latest =
        dams.map((d) => d.created_at).reduce((a, b) => a.isAfter(b) ? a : b);

    return ProvinceRecord(
      thisWeekLevel: _clampPercent(thisWeek),
      lastWeekLevel: _clampPercent(lastWeek),
      lastYearLevel: _clampPercent(lastYear),
      timestamp: latest,
    );
  }

  Future<DamRecord?> getDamByName(String damName) async {
    try {
      final rows = await _client
          .from(_damTable)
          .select()
          .ilike('dam', damName.trim())
          .order('created_at', ascending: false)
          .limit(1);

      final list = List<Map<String, dynamic>>.from(rows as List);
      if (list.isEmpty) return null;
      return DamRecord.fromMap(list.first);
    } catch (e) {
      debugPrint('❌ Supabase getDamByName($damName) error: $e');
      return null;
    }
  }

  Future<DamRecord?> getDamById(String damId) async {
    try {
      final row = await _client
          .from(_damTable)
          .select()
          .eq('id', damId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return DamRecord.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('❌ Supabase getDamById($damId) error: $e');
      return null;
    }
  }
}

final supabaseDamServiceProvider = Provider<SupabaseDamService>((ref) {
  return SupabaseDamService();
});
