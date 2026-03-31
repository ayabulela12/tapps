import 'dart:async';

import 'package:appmaniazar/providers/saved_locations_provider.dart';
import 'package:appmaniazar/services/places_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final placesServiceProvider = Provider((ref) => PlacesService());
final searchResultsProvider = StateProvider<List<PlaceSearchResult>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);

class LocationSearch extends ConsumerStatefulWidget {
  final Function(String) onLocationSelected;

  const LocationSearch({
    super.key,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends ConsumerState<LocationSearch> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    ref.read(searchResultsProvider.notifier).state = [];
    _debounceTimer?.cancel();
  }

  Future<void> _searchPlaces(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      ref.read(searchResultsProvider.notifier).state = [];
      return;
    }

    // Only search if query has at least 2 characters
    if (query.length < 2) {
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      ref.read(isLoadingProvider.notifier).state = true;
      try {
        print('🔍 Searching for places with query: "$query"');
        final places = await ref.read(placesServiceProvider).searchPlaces(query);
        if (!mounted) return;
        print('🔍 Found ${places.length} places: ${places.map((p) => p.mainText).toList()}');
        ref.read(searchResultsProvider.notifier).state = places;
      } catch (e) {
        if (!mounted) return;
        print('❌ Error searching places: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for places: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      if (mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    });
  }

  Future<void> _selectSearchResult(PlaceSearchResult result) async {
    try {
      final details = await ref.read(placesServiceProvider).getPlaceDetails(result.placeId);
      if (!mounted) return;
      widget.onLocationSelected(details.formattedAddress);
      ref.read(savedLocationsProvider.notifier).addLocation(details.formattedAddress);
      _stopSearch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting place details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            child: TextField(
              controller: _searchController,
              onTap: _startSearch,
              onChanged: (value) => _searchPlaces(value),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.outfit(color: Colors.black38),
                prefixIcon: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: _stopSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
        if (_isSearching && searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                return ListTile(
                  title: Text(
                    result.mainText,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    result.secondaryText,
                    style: GoogleFonts.outfit(
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),
      ],
    );
  }
}
