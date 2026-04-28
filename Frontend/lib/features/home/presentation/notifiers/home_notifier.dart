import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../notifiers/home_state.dart';
import '../../../rooms/domain/models/room.dart';

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    return const HomeState();
  }

  Future<void> loadRecommended() async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<dynamic>>('/quartos/recomendados');

      final rooms = (response.data ?? []).map((json) {
        final data = json as Map<String, dynamic>;
        return Room(
          id: data['roomId'] as String? ?? '',
          hotelId: data['hotelId'] as String? ?? '',
          title: data['title'] as String? ?? '',
          hotelName: data['title'] as String? ?? '',
          destination: data['destination'] as String? ?? '',
          description: '',
          imageUrls: [data['imageUrl'] as String? ?? ''],
          rating: data['rating'] as String? ?? '0,0',
          amenities: _parseAmenities(data['amenities']),
          price: _parsePrice(data['price']),
          host: _dummyHost(),
        );
      }).toList();

      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (error) {
      debugPrint('[homeNotifier] Erro ao carregar recomendações: $error');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  List<Amenity> _parseAmenities(List<dynamic>? amenities) {
    if (amenities == null) return [];
    return amenities.map((a) {
      final label = a as String;
      return Amenity(label, _iconForAmenity(label));
    }).toList();
  }

  IconData _iconForAmenity(String label) {
    switch (label.toLowerCase()) {
      case 'wi-fi':
        return Icons.wifi;
      case 'tv':
        return Icons.tv;
      case 'ar-condicionado':
      case 'ar':
        return Icons.ac_unit;
      case 'pool':
      case 'piscina':
        return Icons.pool;
      case 'restaurante':
        return Icons.restaurant;
      case 'spa':
        return Icons.spa;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.check;
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Host _dummyHost() {
    return const Host(
      name: '',
      bio: '',
      imageUrl: '',
      rating: '0,0',
    );
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);