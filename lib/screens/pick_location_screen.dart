import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/models/search_history_item.dart';
import 'package:appmaniazar/providers/places_provider.dart';
import 'package:appmaniazar/views/gradient_container.dart';
import 'package:appmaniazar/widgets/search_history_card.dart';

class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({super.key});

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  final _searchController = TextEditingController();
  final List<SearchHistoryItem> _searchHistory = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('search_history');
      if (historyJson != null) {
        setState(() {
          _searchHistory.clear();
          _searchHistory.addAll(SearchHistoryItem.fromJsonList(historyJson));
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load search history';
      });
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = SearchHistoryItem.toJsonList(_searchHistory);
      await prefs.setString('search_history', historyJson);
    } catch (e) {
      setState(() {
        _error = 'Failed to save search history';
      });
    }
  }

  Future<void> _addToHistory(String query) async {
    final newItem = SearchHistoryItem(
      query: query,
      timestamp: DateTime.now(),
    );

    setState(() {
      _searchHistory.insert(0, newItem);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    await _saveSearchHistory();
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      setState(() {
        _searchHistory.clear();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to clear search history';
      });
    }
  }

  Future<void> _onPlaceSelected(String placeId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details =
          await ref.read(placesServiceProvider).getPlaceDetails(placeId);
      await _addToHistory(details.name);
      if (mounted) {
        Navigator.pop(context, details.name);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get location details';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final placesSearch = ref.watch(placeSearchProvider(_searchQuery));

    return GradientContainer(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Pick Location', style: TextStyles.h2),
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: TextStyles.bodyText,
            decoration: InputDecoration(
              hintText: 'Search for a location...',
              hintStyle: TextStyles.bodyText.copyWith(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _error!,
              style: TextStyles.smallText.copyWith(color: Colors.red),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : placesSearch.when(
                  data: (places) {
                    if (_searchQuery.isEmpty) {
                      return _buildSearchHistory();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return ListTile(
                          title: Text(
                            place.mainText,
                            style: TextStyles.bodyText,
                          ),
                          subtitle: Text(
                            place.secondaryText,
                            style: TextStyles.smallText,
                          ),
                          onTap: () => _onPlaceSelected(place.placeId),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to search locations',
                      style: TextStyles.bodyText.copyWith(color: Colors.red),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final item = _searchHistory[index];
        return SearchHistoryCard(
          location: item.query,
          timestamp: item.timestamp,
          onTap: () => Navigator.pop(context, item.query),
        );
      },
    );
  }
}
