import 'package:appmaniazar/models/province.dart';
import 'package:appmaniazar/models/province_record.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/services/supabase_service.dart';

class AppDataException implements Exception {
  final String message;
  final dynamic originalError;

  AppDataException(this.message, [this.originalError]);

  @override
  String toString() =>
      'AppDataException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

class DamLevelsRecord {
  final double thisWeekLevel;
  final double lastWeekLevel;
  final double lastYearLevel;
  final DateTime timestamp;

  DamLevelsRecord({
    required this.thisWeekLevel,
    required this.lastWeekLevel,
    required this.lastYearLevel,
    required this.timestamp,
  });
}

class SupabaseDamDataService {
  final SupabaseDamService _supabaseDamService;
  static const Map<String, String> _provinceNames = {
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

  SupabaseDamDataService({SupabaseDamService? supabaseDamService})
      : _supabaseDamService = supabaseDamService ?? SupabaseDamService();

  Future<bool> checkConnection() async {
    try {
      await _supabaseDamService.getAllDams();
      return true;
    } catch (e) {
      debugPrint('❌ Supabase connection check failed: $e');
      return false;
    }
  }

  Future<DamLevelsRecord> getDamLevels() async {
    try {
      final totals = await _supabaseDamService.getNationalTotals();
      return DamLevelsRecord(
        thisWeekLevel: totals.thisWeek,
        lastWeekLevel: totals.lastWeek,
        lastYearLevel: totals.lastYear,
        timestamp: totals.timestamp,
      );
    } catch (e) {
      throw AppDataException('Failed to load dam levels', e);
    }
  }

  Future<ProvinceRecord> getProvinceTotals(String provinceCode) {
    try {
      if (!_provinceNames.containsKey(provinceCode.toUpperCase())) {
        throw AppDataException(
          'Invalid province code: $provinceCode. Valid codes are: ${_provinceNames.keys.join(", ")}',
        );
      }
      return _supabaseDamService.getProvinceTotals(provinceCode.toUpperCase());
    } catch (e) {
      debugPrint('❌ Error in getProvinceTotals for $provinceCode: $e');
      throw AppDataException('Failed to load province totals for $provinceCode', e);
    }
  }

  Future<ProvinceRecord> getMetroTotals(String collectionName, String documentId) {
    try {
      const metroToProvince = <String, String>{
        'CityOfCapeTown': 'WC',
        'NelsonMandelaBay': 'EC',
        'EthekwiniMetro': 'KZN',
      };
      final provinceCode = metroToProvince[collectionName];
      if (provinceCode == null) {
        throw AppDataException('Unsupported metro collection: $collectionName');
      }
      return _supabaseDamService.getProvinceTotals(provinceCode);
    } catch (e) {
      debugPrint('❌ Error in getMetroTotals: $e');
      throw AppDataException('Failed to load $collectionName totals', e);
    }
  }

  Future<ProvinceRecord> getCapeTownMetroTotals() {
    return getMetroTotals('CapeTownMetro', 'capeTownMetroDoc');
  }

  Future<List<Map<String, dynamic>>> getProvinceDams(String provinceCode) async {
    try {
      if (!_provinceNames.containsKey(provinceCode.toUpperCase())) {
        debugPrint('⚠️ Invalid province code for dams: $provinceCode');
        throw AppDataException('Invalid province code for dams: $provinceCode');
      }

      final dams = await _supabaseDamService.getDamsByRegion(provinceCode.toUpperCase());
      return dams.map((d) => d.toScreenMap()).toList();
    } catch (e) {
      debugPrint('❌ Error in getProvinceDams for $provinceCode: $e');
      throw AppDataException('Failed to load province dams for $provinceCode', e);
    }
  }

  Stream<List<Province>> getProvinces() {
    return Stream.fromFuture(_getProvincesOnce());
  }

  Future<List<Province>> _getProvincesOnce() async {
    final provinces = <Province>[];
    for (final entry in _provinceNames.entries) {
      final totals = await _supabaseDamService.getProvinceTotals(entry.key);
      provinces.add(
        Province(
          name: entry.value,
          code: entry.key,
          total: totals.thisWeekLevel,
        ),
      );
    }
    return provinces;
  }

  Future<Map<String, dynamic>?> getSpecificDam({
    String? damId,
    String? damName,
    String? collection,
  }) async {
    try {
      if (damName != null && damName.trim().isNotEmpty) {
        final byName = await _supabaseDamService.getDamByName(damName);
        if (byName != null) return byName.toScreenMap();
      }
      if (damId != null && damId.trim().isNotEmpty) {
        final byId = await _supabaseDamService.getDamById(damId);
        if (byId != null) return byId.toScreenMap();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching specific dam: $e');
      return null;
    }
  }
}

final supabaseDamDataServiceProvider = Provider<SupabaseDamDataService>((ref) {
  return SupabaseDamDataService();
});

final specificDamProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, Map<String, String>>((ref, params) async {
  final service = ref.watch(supabaseDamDataServiceProvider);
  return service.getSpecificDam(
    damId: params['damId'],
    damName: params['damName'],
    collection: params['collection'],
  );
});

final damLevelsStreamProvider = FutureProvider<DamLevelsRecord>((ref) {
  final service = ref.watch(supabaseDamDataServiceProvider);
  return service.getDamLevels();
});

final provinceTotalsProvider = FutureProvider.family<ProvinceRecord, String>((ref, provinceCode) {
  final service = ref.watch(supabaseDamDataServiceProvider);
  return service.getProvinceTotals(provinceCode);
});

final provinceDamsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, provinceCode) {
  final service = ref.watch(supabaseDamDataServiceProvider);
  return service.getProvinceDams(provinceCode);
});

