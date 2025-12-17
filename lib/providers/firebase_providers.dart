import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/province_record.dart';
import 'package:appmaniazar/services/firebase_service.dart';

/// Re-exports for firebase service providers
export 'package:appmaniazar/services/firebase_service.dart' 
  show firebaseServiceProvider, provinceDamsProvider;

/// A provider that exposes a stream of metro totals data for a given collection.
/// 
/// The [collectionPath] parameter should be the full path to the document
/// containing the metro data (e.g., 'CityOfCapeTown/documentId').
final metroTotalsProvider = StreamProvider.family<ProvinceRecord, String>((ref, String collectionPath) {
  // Split the path into collection and document ID
  final parts = collectionPath.split('/');
  if (parts.length != 2) {
    throw ArgumentError('Invalid collection path. Expected format: "collection/documentId"');
  }
  final collectionName = parts[0];
  final documentId = parts[1];
  
  return ref.watch(firebaseServiceProvider).getMetroTotals(collectionName, documentId);
});
