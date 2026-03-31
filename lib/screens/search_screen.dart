import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/views/gradient_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String? _selectedLocation;
  bool _isLoading = false;
  String? _error;

  Future<void> _navigateToLocationPicker() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final location = await Navigator.pushNamed<String>(
        context,
        '/pick_location',
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
        _isLoading = false;
      });

      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location selected: $location'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to select location: ${e.toString()}';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report',
                style: TextStyles.h1,
              ),
              const SizedBox(height: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isLoading ? null : _navigateToLocationPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: _error != null 
                          ? Border.all(color: Colors.red, width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: _error != null ? Colors.red : Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoading
                              ? const LinearProgressIndicator()
                              : Text(
                                  _selectedLocation ?? 'Select location',
                                  style: TextStyles.subtitleText.copyWith(
                                    color: _selectedLocation != null 
                                        ? Colors.black87 
                                        : Colors.black38,
                                  ),
                                ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _error != null ? Colors.red : Colors.black54,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyles.subtitleText.copyWith(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_selectedLocation != null && !_isLoading) ...[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Report for $_selectedLocation',
                        style: TextStyles.subtitleText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
