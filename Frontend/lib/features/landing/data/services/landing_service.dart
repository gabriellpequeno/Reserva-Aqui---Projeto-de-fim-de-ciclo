import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../rooms/domain/models/room.dart';

class LandingService {
  final Ref _ref;
  LandingService(this._ref);

  Future<List<Room>> getFeaturedRooms() async {
    final dio = _ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/quartos/recomendados');
    final data = response.data ?? [];
    final rooms = data.map((json) {
      final d = json as Map<String, dynamic>;
      return Room(
        id: d['roomId'] as String? ?? '',
        hotelId: d['hotelId'] as String? ?? '',
        title: d['title'] as String? ?? '',
        hotelName: d['title'] as String? ?? '',
        destination: d['destination'] as String? ?? '',
        description: '',
        imageUrls: [d['imageUrl'] as String? ?? ''],
        rating: d['rating'] as String? ?? '0,0',
        amenities: _parseAmenities(d['amenities']),
        price: _parsePrice(d['price']),
        host: const Host(name: '', bio: '', imageUrl: '', rating: '0,0'),
      );
    }).toList();

    return rooms.take(6).toList();
  }

  List<Amenity> _parseAmenities(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw.map((a) {
      final label = a as String;
      return Amenity(label, _iconFor(label));
    }).toList();
  }

  IconData _iconFor(String label) {
    switch (label.toLowerCase()) {
      case 'wi-fi': return Icons.wifi;
      case 'tv': return Icons.tv;
      case 'ar-condicionado': case 'ar': return Icons.ac_unit;
      case 'pool': case 'piscina': return Icons.pool;
      case 'restaurante': return Icons.restaurant;
      case 'spa': return Icons.spa;
      case 'fitness': return Icons.fitness_center;
      default: return Icons.check;
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}

final landingServiceProvider = Provider<LandingService>(
  (ref) => LandingService(ref),
);
