import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../utils/Usuario.dart';
import '../../domain/models/favorite_hotel.dart';

class FavoritesNotifier extends AsyncNotifier<List<FavoriteHotel>> {
  @override
  Future<List<FavoriteHotel>> build() async {
    final auth = await ref.watch(authProvider.future);
    if (!auth.isAuthenticated) return [];

    final List<FavoriteHotel> result = [];
    await ref.read(usuarioServiceProvider).listFavoritos(
      onSuccess: (data) {
        result.addAll(data.map(FavoriteHotel.fromJson));
      },
      onError: (msg) => throw Exception(msg),
    );
    return result;
  }

  Future<void> removeFavorite(String hotelId) async {
    await ref.read(usuarioServiceProvider).removeFavorito(
      hotelId: hotelId,
      onSuccess: () {
        final current = state.value ?? [];
        state = AsyncData(current.where((h) => h.hotelId != hotelId).toList());
      },
      onError: (msg) => throw Exception(msg),
    );
  }

  Future<void> addFavorite(String hotelId) async {
    await ref.read(usuarioServiceProvider).addFavorito(
      hotelId: hotelId,
      onSuccess: (json) {
        final hotel = FavoriteHotel.fromJson(json);
        state = AsyncData([...state.value ?? [], hotel]);
      },
      onError: (msg) => throw Exception(msg),
    );
  }

  bool isFavorite(String hotelId) {
    return state.value?.any((h) => h.hotelId == hotelId) ?? false;
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<FavoriteHotel>>(
        FavoritesNotifier.new);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

final filteredFavoritesProvider = Provider<List<FavoriteHotel>>((ref) {
  final favorites = ref.watch(favoritesProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return favorites;

  return favorites.where((h) {
    return h.nomeHotel.toLowerCase().contains(query) ||
        '${h.cidade}, ${h.uf}'.toLowerCase().contains(query) ||
        h.bairro.toLowerCase().contains(query);
  }).toList();
});
