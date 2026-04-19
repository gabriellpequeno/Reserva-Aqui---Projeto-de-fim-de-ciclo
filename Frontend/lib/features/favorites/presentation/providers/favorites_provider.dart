import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/favorite_room.dart';

class FavoritesNotifier extends Notifier<List<FavoriteRoom>> {
  @override
  List<FavoriteRoom> build() {
    // Mock initial data
    return [
      const FavoriteRoom(
        id: '1',
        title: 'Suíte Luxo Vista Mar',
        hotelName: 'Hotel Paradiso',
        destination: 'Rio de Janeiro, RJ',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        rating: '4.8',
        price: 450.0,
        amenities: [Icons.wifi, Icons.ac_unit, Icons.pool],
      ),
      const FavoriteRoom(
        id: '2',
        title: 'Quarto Standard Casal',
        hotelName: 'Pousada das Flores',
        destination: 'Gramado, RS',
        imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        rating: '4.5',
        price: 280.0,
        amenities: [Icons.wifi, Icons.tv],
      ),
      const FavoriteRoom(
        id: '3',
        title: 'Bangalô Presidencial',
        hotelName: 'Resort Tropical',
        destination: 'Porto de Galinhas, PE',
        imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        rating: '5.0',
        price: 1200.0,
        amenities: [Icons.wifi, Icons.ac_unit, Icons.pool, Icons.hot_tub],
      ),
    ];
  }

  void removeFavorite(String id) {
    state = state.where((room) => room.id != id).toList();
  }

  void toggleFavorite(FavoriteRoom room) {
    if (state.any((r) => r.id == room.id)) {
      removeFavorite(room.id);
    } else {
      state = [...state, room];
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<FavoriteRoom>>(FavoritesNotifier.new);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) => state = value;
}
final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

final filteredFavoritesProvider = Provider<List<FavoriteRoom>>((ref) {
  final List<FavoriteRoom> favorites = ref.watch(favoritesProvider);
  final String query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return favorites;

  return favorites.where((FavoriteRoom room) {
    final title = room.title.toLowerCase();
    final hotel = room.hotelName.toLowerCase();
    final dest = room.destination.toLowerCase();
    
    return title.contains(query) ||
           hotel.contains(query) ||
           dest.contains(query);
  }).toList();
});
