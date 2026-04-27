import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/search_providers.dart';
import '../../domain/models/amenity.dart';
import '../../domain/models/search_result_room.dart';
import '../../data/services/search_service.dart';

class SearchState {
  final String destination;
  final int? guests;
  final DateTimeRange? dateRange;
  final Set<int> selectedAmenityIds;
  final List<Amenity> availableAmenities;
  final List<SearchResultRoom> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;

  SearchState({
    this.destination = '',
    this.guests,
    this.dateRange,
    this.selectedAmenityIds = const {},
    this.availableAmenities = const [],
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? destination,
    int? guests,
    DateTimeRange? dateRange,
    Set<int>? selectedAmenityIds,
    List<Amenity>? availableAmenities,
    List<SearchResultRoom>? results,
    bool? isLoading,
    String? error,
    bool? hasSearched,
  }) {
    return SearchState(
      destination: destination ?? this.destination,
      guests: guests ?? this.guests,
      dateRange: dateRange ?? this.dateRange,
      selectedAmenityIds: selectedAmenityIds ?? this.selectedAmenityIds,
      availableAmenities: availableAmenities ?? this.availableAmenities,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value, error: null);
  }

  void updateGuests(int? value) {
    state = state.copyWith(guests: value, error: null);
  }

  void updateDateRange(DateTimeRange? value) {
    state = state.copyWith(dateRange: value, error: null);
  }

  void toggleAmenity(int catalogoId) {
    final newIds = Set<int>.from(state.selectedAmenityIds);
    if (newIds.contains(catalogoId)) {
      newIds.remove(catalogoId);
    } else {
      newIds.add(catalogoId);
    }
    state = state.copyWith(selectedAmenityIds: newIds);
  }

  void setAmenities(Set<int> amenityIds) {
    state = state.copyWith(selectedAmenityIds: amenityIds);
  }

  Future<void> performSearch() async {
    if (state.destination.trim().length < 2) {
      state = state.copyWith(
        error: 'Destino deve ter no mínimo 2 caracteres',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final searchService = ref.read(searchServiceProvider);
      final avaliacaoService = ref.read(avaliacaoServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);

      // 1. Call search API
      final dtos = await searchService.searchRooms(
        q: state.destination.trim(),
        checkin: state.dateRange?.start,
        checkout: state.dateRange?.end,
        hospedes: state.guests,
        amenidadeIds:
            state.selectedAmenityIds.isNotEmpty
                ? state.selectedAmenityIds.toList()
                : null,
      );

      // 2. Convert DTOs to domain models
      var results = dtos.map((dto) => SearchResultRoom.fromDto(dto)).toList();

      // 3. Fetch ratings for unique hotels (in parallel)
      final uniqueHotelIds = <String>{};
      for (final room in results) {
        uniqueHotelIds.add(room.hotelId);
      }

      final ratingFutures = uniqueHotelIds.map((hotelId) =>
          avaliacaoService.fetchHotelRating(hotelId).then((summary) =>
              (hotelId, summary)));
      final ratings = await Future.wait(ratingFutures);
      final ratingMap = Map.fromEntries(ratings);

      // 4. Fetch room images (in parallel)
      final imageFutures = results.map((room) =>
          uploadService
              .fetchFirstRoomPhotoUrl(room.hotelId, room.roomId)
              .then((url) => (room.roomId, url)));
      final images = await Future.wait(imageFutures);
      final imageMap = Map.fromEntries(images);

      // 5. Merge data into SearchResultRoom
      results = results
          .map((room) {
            final ratingData = ratingMap[room.hotelId];
            return room.copyWith(
              imageUrl: imageMap[room.roomId],
              rating: ratingData?.average,
              reviewCount: ratingData?.count ?? 0,
            );
          })
          .toList();

      // 6. Derive available amenities (dedup by catalogoId)
      final amenitiesMap = <int, Amenity>{};
      for (final room in results) {
        for (final amenity in room.amenities) {
          amenitiesMap.putIfAbsent(amenity.catalogoId, () => amenity);
        }
      }
      final availableAmenities = amenitiesMap.values.toList()
        ..sort((a, b) => a.categoria.compareTo(b.categoria));

      state = state.copyWith(
        results: results,
        availableAmenities: availableAmenities,
        isLoading: false,
        hasSearched: true,
        error: null,
      );
    } on SearchException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
        results: [],
        availableAmenities: [],
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao buscar quartos: $e',
        isLoading: false,
        results: [],
        availableAmenities: [],
        hasSearched: true,
      );
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
    SearchNotifier.new);

