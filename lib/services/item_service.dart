import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shoe.dart';

class ItemService {
  ItemService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Shoe>> fetchActiveItems() async {
    final rows = await _client
        .from('items')
        .select()
        .ilike('status', 'active')
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => Shoe.fromMap(Map<String, dynamic>.from(row as Map)))
        .where((shoe) => shoe.image.isNotEmpty)
        .toList();
  }
}
