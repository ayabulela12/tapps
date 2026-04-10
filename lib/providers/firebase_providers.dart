import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/province_record.dart';
import 'package:appmaniazar/services/supabase_dam_service.dart';

/// Re-exports for dam data providers
export 'package:appmaniazar/services/supabase_dam_service.dart' 
  show supabaseDamDataServiceProvider, provinceDamsProvider;

/// A provider that exposes metro totals data for a given collection.
/// 
/// The [collectionPath] parameter should be the full path to the document
/// containing the metro data (e.g., 'CityOfCapeTown/documentId').
final metroTotalsProvider = FutureProvider.family<ProvinceRecord, String>((ref, String collectionPath) {
  // Split the path into collection and document ID
  final parts = collectionPath.split('/');
  if (parts.length != 2) {
    throw ArgumentError('Invalid collection path. Expected format: "collection/documentId"');
  }
  final collectionName = parts[0];
  final documentId = parts[1];
  
  return ref.watch(supabaseDamDataServiceProvider).getMetroTotals(collectionName, documentId);
});
