import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../favorites/domain/models/favorite_room.dart';

class SearchState {
  final String destination;
  final int guests;
  final DateTimeRange? dateRange;
  final List<FavoriteRoom> results;
  final bool isLoading;

  SearchState({
    this.destination = '',
    this.guests = 1,
    this.dateRange,
    this.results = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? destination,
    int? guests,
    DateTimeRange? dateRange,
    List<FavoriteRoom>? results,
    bool? isLoading,
  }) {
    return SearchState(
      destination: destination ?? this.destination,
      guests: guests ?? this.guests,
      dateRange: dateRange ?? this.dateRange,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value);
  }

  void updateGuests(int value) {
    state = state.copyWith(guests: value);
  }

  void updateDateRange(DateTimeRange value) {
    state = state.copyWith(dateRange: value);
  }

  Future<void> performSearch() async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock results based on the favorite rooms list or similar
    // For now, let's just return some mock hotels
    state = state.copyWith(
      isLoading: false,
      results: [
        FavoriteRoom(
          id: '1',
          title: 'Quarto Deluxe',
          hotelName: 'Grand Hotel Budapest',
          destination: 'Budapest',
          price: 1200.0,
          rating: '4.8',
          imageUrl: 'lib/assets/images/home_page.jpeg',
          amenities: [Icons.wifi, Icons.king_bed, Icons.coffee, Icons.ac_unit],
        ),
        FavoriteRoom(
          id: '2',
          title: 'Suíte Presidencial',
          hotelName: 'Copacabana Palace',
          destination: 'Rio de Janeiro',
          price: 2500.0,
          rating: '4.9',
          imageUrl: 'lib/assets/images/home_page.jpeg',
          amenities: [Icons.wifi, Icons.pool, Icons.spa],
        ),
        FavoriteRoom(
          id: '3',
          title: 'Quarto Superior',
          hotelName: 'Plaza Hotel',
          destination: 'New York',
          price: 1800.0,
          rating: '4.7',
          imageUrl: 'lib/assets/images/home_page.jpeg',
          amenities: [Icons.wifi, Icons.tv, Icons.local_bar],
        ),
      ],
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

