import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/province_record.dart';
import 'package:appmaniazar/services/supabase_dam_service.dart';

// Re-export Supabase providers so screens that import firebase_providers
// continue to compile without any import changes.
export 'package:appmaniazar/services/supabase_dam_service.dart'
    show
        supabaseDamDataServiceProvider,
        provinceDamsProvider,
        provinceTotalsProvider,
        damLevelsStreamProvider,
        specificDamProvider;

/// Metro totals — computed from Supabase dam_levels rows that belong to
/// dams inside the metro area.
///
/// Pass the metro identifier string that maps to a known set of dam names
/// or a sub-region filter, e.g.:
///   'CityOfCapeTown'  → Western Cape dams in the City of Cape Town metro
///   'NelsonMandelaBay' → Eastern Cape dams in the Nelson Mandela Bay metro
///   'EThekwini'       → KwaZulu-Natal dams in the eThekwini metro
///
/// For now, since Supabase does not have a metro column, this falls back to
/// the province totals for the relevant province — a good approximation
/// until a `metro` column is added to the dam_levels table.
final metroTotalsProvider =
    FutureProvider.family<ProvinceRecord, String>((ref, metroKey) async {
  final svc = ref.watch(supabaseDamDataServiceProvider);

  // Map metro key → province code
  const metroToProvince = {
    // Firestore path style (legacy — kept for backward compat)
    'CityOfCapeTown': 'WC',
    'NelsonMandelaMetro': 'EC',
    'EThekwiniMunicipality': 'KZN',
    // New clean keys
    'NelsonMandelaBay': 'EC',
    'EThekwini': 'KZN',
  };

  // Also handle legacy Firestore path format: 'Collection/docId'
  final resolvedKey = metroKey.contains('/')
      ? metroKey.split('/').first
      : metroKey;

  final provinceCode = metroToProvince[resolvedKey];

  if (provinceCode == null) {
    // Unknown metro — return empty record rather than crashing
    return ProvinceRecord(
      thisWeekLevel: 0,
      lastWeekLevel: 0,
      lastYearLevel: 0,
      timestamp: DateTime.now(),
    );
  }

  return svc.getProvinceTotals(provinceCode);
});
