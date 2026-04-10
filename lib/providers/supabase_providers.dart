import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Direct access to the initialized Supabase client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Convenience provider: fetch rows from a table once.
final supabaseSelectAllProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, table) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from(table).select();
  return List<Map<String, dynamic>>.from(rows as List);
});

