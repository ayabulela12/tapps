import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/services/places_service.dart';

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService();
});

final placeSearchProvider = FutureProvider.autoDispose.family<List<PlaceSearchResult>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final placesService = ref.read(placesServiceProvider);
  return placesService.searchPlaces(query);
});

final placeDetailsProvider = FutureProvider.autoDispose.family<PlaceDetails, String>((ref, placeId) {
  final placesService = ref.read(placesServiceProvider);
  return placesService.getPlaceDetails(placeId);
});
