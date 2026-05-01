import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../favorites/domain/models/favorite_room.dart';
import '../../data/models/search_room_result.dart';
import '../../data/services/search_service.dart';

class SearchState {
  final String destination;
  final int guests;
  final DateTimeRange? dateRange;
  final List<FavoriteRoom> results;
  final bool isLoading;
  final String? errorMessage;
  final List<String> suggestions;
  final bool showSuggestions;
  final bool showGuestsPicker;

  SearchState({
    this.destination = '',
    this.guests = 1,
    this.dateRange,
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.suggestions = const [],
    this.showSuggestions = false,
    this.showGuestsPicker = false,
  });

  SearchState copyWith({
    String? destination,
    int? guests,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    List<FavoriteRoom>? results,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<String>? suggestions,
    bool? showSuggestions,
    bool? showGuestsPicker,
  }) {
    return SearchState(
      destination: destination ?? this.destination,
      guests: guests ?? this.guests,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      suggestions: suggestions ?? this.suggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showGuestsPicker: showGuestsPicker ?? this.showGuestsPicker,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  late final SearchService _service;

  @override
  SearchState build() {
    _service = ref.watch(searchServiceProvider);
    return SearchState();
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value, showSuggestions: false);
  }

  Future<void> fetchSuggestions() async {
    if (state.showSuggestions) {
      state = state.copyWith(showSuggestions: false);
      return;
    }

    final q = state.destination.trim();

    try {
      final results = await _service.searchRooms(q: q);
      final seen = <String>{};
      final suggestions = <String>[];
      for (final r in results) {
        if (seen.add(r.nomeHotel)) {
          suggestions.add('${r.nomeHotel} — ${r.cidade}, ${r.uf}');
        }
        if (suggestions.length >= 6) break;
      }
      state = state.copyWith(suggestions: suggestions, showSuggestions: true, showGuestsPicker: false);
    } catch (_) {
      state = state.copyWith(suggestions: [], showSuggestions: false);
    }
  }

  void selectSuggestion(String label, void Function(String) updateTextField) {
    final hotelName = label.split(' — ').first;
    updateTextField(hotelName);
    state = state.copyWith(
      destination: hotelName,
      suggestions: [],
      showSuggestions: false,
    );
    performSearch();
  }

  void toggleGuestsPicker() {
    state = state.copyWith(
      showGuestsPicker: !state.showGuestsPicker,
      showSuggestions: false,
    );
  }

  void hideAllPickers() {
    state = state.copyWith(showSuggestions: false, showGuestsPicker: false);
  }

  void updateGuests(int value) {
    state = state.copyWith(guests: value);
  }

  void updateDateRange(DateTimeRange value) {
    state = state.copyWith(dateRange: value);
  }

  void updateCheckin(DateTime date) {
    final current = state.dateRange;
    final checkout = (current != null && current.end.isAfter(date))
        ? current.end
        : date.add(const Duration(days: 1));
    state = state.copyWith(dateRange: DateTimeRange(start: date, end: checkout));
  }

  void updateCheckout(DateTime date) {
    final checkin = state.dateRange?.start ?? DateTime.now();
    if (!date.isAfter(checkin)) return;
    state = state.copyWith(dateRange: DateTimeRange(start: checkin, end: date));
  }

  Future<void> performSearch() async {
    final q = state.destination.trim();
    final dateRange = state.dateRange;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await _service.searchRooms(
        q: q,
        checkin: dateRange != null ? _formatIso(dateRange.start) : null,
        checkout: dateRange != null ? _formatIso(dateRange.end) : null,
        hospedes: state.guests > 0 ? state.guests : null,
      );

      final baseUrl = kIsWeb
          ? 'http://localhost:3000/api/v1'
          : 'http://10.0.2.2:3000/api/v1';

      state = state.copyWith(
        isLoading: false,
        results: results.map((r) => _toFavoriteRoom(r, baseUrl)).toList(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao buscar. Verifique sua conexão e tente novamente.',
      );
    }
  }

  FavoriteRoom _toFavoriteRoom(SearchRoomResult r, String baseUrl) {
    return FavoriteRoom(
      id: r.quartoId.toString(),
      hotelId: r.hotelId,
      title: r.descricao?.isNotEmpty == true
          ? r.descricao!
          : 'Quarto #${r.quartoId}',
      hotelName: r.nomeHotel,
      destination: '${r.cidade}, ${r.uf}',
      imageUrl: '$baseUrl/uploads/hotels/${r.hotelId}/rooms/${r.quartoId}',
      rating: '—',
      amenities: _mapItemsToIcons(r.itens),
      price: double.tryParse(r.valorDiaria) ?? 0.0,
    );
  }

  List<IconData> _mapItemsToIcons(List<QuartoItem> itens) {
    final icons = <IconData>[];
    for (final item in itens) {
      if (icons.length >= 4) break;
      final key = '${item.nome} ${item.categoria}'.toLowerCase();
      if (_contains(key, ['wifi', 'internet'])) {
        icons.add(Icons.wifi);
      } else if (_contains(key, ['cama', 'bed'])) {
        icons.add(Icons.king_bed);
      } else if (_contains(key, ['cafe', 'café', 'manha', 'manhã'])) {
        icons.add(Icons.free_breakfast);
      } else if (_contains(key, ['ar', 'ac', 'condicionado'])) {
        icons.add(Icons.ac_unit);
      } else if (_contains(key, ['piscina', 'pool'])) {
        icons.add(Icons.pool);
      } else if (_contains(key, ['spa', 'massagem'])) {
        icons.add(Icons.spa);
      } else if (_contains(key, ['tv', 'televisao', 'televisão'])) {
        icons.add(Icons.tv);
      } else if (_contains(key, ['estacionamento', 'vaga', 'garagem'])) {
        icons.add(Icons.local_parking);
      }
    }
    return icons;
  }

  bool _contains(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _formatIso(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
