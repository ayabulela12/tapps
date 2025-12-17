import 'dart:async';

import 'package:appmaniazar/models/province.dart';
import 'package:appmaniazar/models/province_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseException implements Exception {
  final String message;
  final dynamic originalError;

  FirebaseException(this.message, [this.originalError]);

  @override
  String toString() => 'FirebaseException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
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

  factory DamLevelsRecord.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw FirebaseException('Document does not exist');
    }

    try {
      final data = doc.data() as Map<String, dynamic>;
      
      return DamLevelsRecord(
        thisWeekLevel: (data['this_week_level'] ?? 0.0).toDouble(),
        lastWeekLevel: (data['last_week_level'] ?? 0.0).toDouble(),
        lastYearLevel: (data['last_year_level'] ?? 0.0).toDouble(),
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw FirebaseException('Failed to parse document data', e);
    }
  }
}

class FirebaseService {
  final FirebaseFirestore _firestore;
  static const String _damLevelsCollection = 'Grand_total';
  static const String _damLevelsDocId = 'HvLx0oOi0Uxgik0J7hMy';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  FirebaseService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<bool> checkConnection() async {
    try {
      // Only enable network, don't terminate or clear persistence
      await _firestore.enableNetwork();
      // Try a simple query to verify connection
      await _firestore.collection(_damLevelsCollection).doc(_damLevelsDocId).get();
      return true;
    } catch (e) {
      debugPrint('❌ Firebase connection check failed: $e');
      return false;
    }
  }

  Stream<T> _withStreamRetry<T>(Stream<T> Function() operation, String operationName) {
    return Stream.multi((controller) async {
      int attempts = 0;
      StreamSubscription<T>? subscription;
      bool hasError = false;

      void retry() async {
        await subscription?.cancel();

        if (attempts >= _maxRetries) {
          controller.addError(FirebaseException('All retry attempts failed for $operationName'));
          await controller.close();
          return;
        }

        if (attempts > 0) {
          debugPrint('⚠️ Attempt $attempts failed for $operationName, retrying...');
          await Future.delayed(_retryDelay * attempts);
        }

        subscription = operation().listen(
          (data) {
            if (!controller.isClosed) controller.add(data);
            hasError = false;
          },
          onError: (error) {
            hasError = true;
            attempts++;
            retry();
          },
          onDone: () {
            if (!hasError && !controller.isClosed) controller.close();
          },
        );
      }

      retry();

      // Clean up subscription when the controller is closed
      controller.onCancel = () {
        subscription?.cancel();
      };
    });
  }

  Stream<DamLevelsRecord> getDamLevels() {
    try {
      return _withStreamRetry(() {
        return _firestore
            .collection(_damLevelsCollection)
            .doc(_damLevelsDocId)
            .snapshots()
            .handleError((error) {
              debugPrint('❌ Error fetching dam levels: $error');
              throw FirebaseException('Failed to fetch dam levels', error);
            })
            .map((snapshot) => DamLevelsRecord.fromFirestore(snapshot));
      }, 'getDamLevels');
    } catch (e) {
      throw FirebaseException('Failed to create dam levels stream', e);
    }
  }

  Stream<ProvinceRecord> getProvinceTotals(String provinceCode) {
    try {
      // Map province codes to their respective document IDs and collection names
      final Map<String, Map<String, String>> provinceConfigs = {
        'WC': {
          'collection': 'WCTotals',
          'docId': 'rxpK7cf0ImOZtqJBWndu',  // Western Cape
        },
        'EC': {
          'collection': 'ECTotals',
          'docId': 'HQ4VGbK8VFe8yXZ97fVr',  // Eastern Cape
        },
        'NC': {
          'collection': 'NCTotals',
          'docId': 'tkUmSThRNbxtSGhmtJ2q',  // Northern Cape
        },
        'FS': {
          'collection': 'FSTotals',
          'docId': 'iqSa1Whljfk63r7W5hiT',  // Free State
        },
        'KZN': {
          'collection': 'KZNTotals',
          'docId': 'TWRSTXhJkdlK4g1fANlG',  // KwaZulu-Natal
        },
        'GP': {
          'collection': 'GPTotals',
          'docId': 'pEF90QvqBNV64hJOhx1S',  // Gauteng
        },
        'MP': {
          'collection': 'MPTotals',
          'docId': 'kG0WBCOI26wF7kxeGw9I',  // Mpumalanga
        },
        'LP': {
          'collection': 'LPTotals',
          'docId': '8cP6petEFKZx8ScGsnF8',  // Limpopo
        },
        'NW': {
          'collection': 'NWTotals',
          'docId': 'hw8PSceWv0Kw2cJ2CdXf',  // North West
        },
        'NelsonMandelaMetro': {
          'collection': 'NelsonMandelaMetro',
          'docId': '2uB3nGZnKKtg6y4ZaytH',  // Nelson Mandela Metro
        },

      };

      // Validate province code
      if (!provinceConfigs.containsKey(provinceCode)) {
        debugPrint('⚠️ Invalid province code: $provinceCode');
        throw FirebaseException('Invalid province code: $provinceCode. Valid codes are: ${provinceConfigs.keys.join(", ")}');
      }

      final config = provinceConfigs[provinceCode]!;
      final collectionName = config['collection']!;
      final docId = config['docId']!;
      
      debugPrint('📊 Fetching data for province: $provinceCode');
      debugPrint('📁 Collection: $collectionName');
      debugPrint('📄 Document ID: $docId');
      
      return _withStreamRetry(() {
        return _firestore
            .collection(collectionName)
            .doc(docId)
            .snapshots()
            .handleError((error) {
              debugPrint('❌ Error fetching province totals for $provinceCode: $error');
              throw FirebaseException('Failed to fetch province totals for $provinceCode', error);
            })
            .map((snapshot) {
              if (!snapshot.exists) {
                debugPrint('⚠️ No data found for province: $provinceCode');
                throw FirebaseException('No data found for province: $provinceCode');
              }
              debugPrint('✅ Successfully fetched data for province: $provinceCode');
              return ProvinceRecord.fromFirestore(snapshot);
            });
      }, 'getProvinceTotals');
    } catch (e) {
      debugPrint('❌ Error in getProvinceTotals for $provinceCode: $e');
      throw FirebaseException('Failed to create province totals stream for $provinceCode', e);
    }
  }

  Stream<ProvinceRecord> getMetroTotals(String collectionName, String documentId) {
    try {
      debugPrint('📊 Fetching metro data for $collectionName/$documentId');
      
      return _withStreamRetry(() {
        return _firestore
            .collection(collectionName)
            .doc(documentId)
            .snapshots()
            .handleError((error) {
              debugPrint('❌ Error fetching $collectionName totals: $error');
              throw FirebaseException('Failed to fetch $collectionName totals', error);
            })
            .map((snapshot) {
              if (!snapshot.exists) {
                debugPrint('⚠️ No data found for $collectionName/$documentId');
                throw FirebaseException('No data found for $collectionName/$documentId');
              }
              debugPrint('✅ Successfully fetched data for $collectionName/$documentId');
              return ProvinceRecord.fromFirestore(snapshot);
            });
      }, 'getMetroTotals');
    } catch (e) {
      debugPrint('❌ Error in getMetroTotals: $e');
      throw FirebaseException('Failed to create $collectionName totals stream', e);
    }
  }

  Stream<ProvinceRecord> getCapeTownMetroTotals() {
    return getMetroTotals('CapeTownMetro', 'capeTownMetroDoc');
  }

  Stream<List<Map<String, dynamic>>> getProvinceDams(String provinceCode) {
    try {
      // Map province codes to their respective collection names
      final Map<String, String> provinceDamsCollections = {
        'WC': 'WCDams',
        'EC': 'ECDams',
        'NC': 'NCDams',
        'FS': 'FSDams',
        'KZN': 'KZNDams',
        'GP': 'GPDams',
        'MP': 'MPDams',
        'LP': 'LPDams',
        'NW': 'NWDams',
      };

      if (!provinceDamsCollections.containsKey(provinceCode)) {
        debugPrint('⚠️ Invalid province code for dams: $provinceCode');
        throw FirebaseException('Invalid province code for dams: $provinceCode');
      }

      final collectionName = provinceDamsCollections[provinceCode]!;
      debugPrint('🌊 Fetching dams for province: $provinceCode');
      debugPrint('📂 Collection: $collectionName');

      return _withStreamRetry(() {
        return _firestore
            .collection(collectionName)
            .snapshots()
            .handleError((error) {
              debugPrint('❌ Error fetching province dams for $provinceCode: $error');
              
              // If it's a permission error, return an empty list instead of throwing an exception
              if (error.code == 'permission-denied') {
                debugPrint('🔒 Permission denied for $provinceCode dams collection');
                return Stream.value([]);
              }
              
              throw FirebaseException('Failed to fetch province dams for $provinceCode', error);
            })
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                debugPrint('ℹ️ No dams found for province: $provinceCode');
              } else {
                debugPrint('✅ Successfully fetched ${snapshot.docs.length} dams for province: $provinceCode');
              }
              return snapshot.docs
                  .map((doc) => {
                        'id': doc.id,
                        'name': doc.data()['name'] ?? 'Unknown Dam',
                        'this_week_level': (doc.data()['total'] ?? 0).toDouble(),
                        // Add location if available
                        'location': _getDefaultLocation(doc.data()['name'] ?? ''),
                        // Add capacity if available
                        'capacity': _getDefaultCapacity(doc.data()['name'] ?? ''),
                      })
                  .toList();
            });
      }, 'getProvinceDams');
    } catch (e) {
      debugPrint('❌ Error in getProvinceDams for $provinceCode: $e');
      throw FirebaseException('Failed to create province dams stream for $provinceCode', e);
    }
  }

  // Helper method to provide default location based on dam name
  String _getDefaultLocation(String damName) {
    final locationMap = {
      'Leeugamka Dam': 'Western Cape',
      // Add more dams and their locations as you discover them
    };
    return locationMap[damName] ?? 'Location Not Available';
  }

  // Helper method to provide default capacity based on dam name
  String _getDefaultCapacity(String damName) {
    final capacityMap = {
      'Leeugamka Dam': 'Capacity Not Available',
      // Add more dams and their capacities as you discover them
    };
    return capacityMap[damName] ?? 'Capacity Not Available';
  }

  Stream<List<Province>> getProvinces() {
    try {
      return _firestore
          .collection('provinces')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Province.fromFirestore(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('🔴 Error getting provinces: $e');
      rethrow;
    }
  }

  // Fetch a specific dam by its ID from a specific collection
  Future<Map<String, dynamic>?> getSpecificDam(String damId, {String collection = 'WCDams'}) async {
    try {
      debugPrint('🔍 Fetching specific dam with ID: $damId from collection: $collection');
      
      final damDoc = await _firestore
          .collection(collection)
          .doc(damId)
          .get();

      if (!damDoc.exists) {
        debugPrint('❌ No dam found with ID: $damId in collection: $collection');
        return null;
      }

      final damData = damDoc.data();
      if (damData == null) {
        debugPrint('❌ Dam document is empty for ID: $damId in collection: $collection');
        return null;
      }

      final damDetails = {
        'id': damDoc.id,
        'name': damData['name'] ?? 'Unknown Dam',
        'total_level': damData['total_level'] ?? 0.0,
        'this_week_level': damData['this_week_level'] ?? 0.0,
        'last_week_level': damData['last_week_level'] ?? 0.0,
        'last_year_level': damData['last_year_level'] ?? 0.0,
        'location': damData['location'] ?? 'Location not specified',
        'capacity': damData['capacity'] ?? 'Capacity not specified',
      };

      debugPrint('✅ Successfully fetched dam details: ${damDetails['name']}');
      return damDetails;
    } catch (e) {
      debugPrint('❌ Error fetching specific dam: $e');
      return null;
    }
  }
}

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Provider for getting a specific dam by ID and collection
final specificDamProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, Map<String, String>>((ref, params) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getSpecificDam(
    params['damId'] ?? '',
    collection: params['collection'] ?? 'WCDams',
  );
});

final damLevelsStreamProvider = StreamProvider<DamLevelsRecord>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getDamLevels();
});

final provinceTotalsProvider = StreamProvider.family<ProvinceRecord, String>((ref, provinceCode) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getProvinceTotals(provinceCode);
});

/// A provider that exposes a stream of province dams data for a given province code.
///
/// The [provinceCode] parameter should be a valid province code (e.g., 'WC' for Western Cape).
final provinceDamsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, String provinceCode) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getProvinceDams(provinceCode);
});
