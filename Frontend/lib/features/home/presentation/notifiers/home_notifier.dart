import 'package:flutter/foundation.dart' show kIsWeb;
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

      final baseHost = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

      final rooms = (response.data ?? []).map((json) {
        final data = json as Map<String, dynamic>;
        final rawImageUrl = data['imageUrl'] as String? ?? '';
        final imageUrl = rawImageUrl.startsWith('/')
            ? '$baseHost$rawImageUrl'
            : rawImageUrl;
        return Room(
          id: data['roomId'] as String? ?? '',
          hotelId: data['hotelId'] as String? ?? '',
          title: data['title'] as String? ?? '',
          hotelName: data['title'] as String? ?? '',
          destination: data['destination'] as String? ?? '',
          description: '',
          imageUrls: [imageUrl],
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
    final seen = <IconData>{};
    final result = <Amenity>[];
    for (final a in amenities) {
      if (result.length >= 4) break;
      final label = a as String;
      final icon = _iconForAmenity(label);
      if (seen.add(icon)) result.add(Amenity(label, icon));
    }
    return result;
  }

  IconData _iconForAmenity(String label) {
    final l = label.toLowerCase();
    if (_has(l, ['wifi', 'wi-fi', 'internet'])) return Icons.wifi;
    if (_has(l, ['ar', 'condicionado'])) return Icons.ac_unit;
    if (_has(l, ['tv', 'televisao', 'televisão'])) return Icons.tv;
    if (_has(l, ['piscina', 'pool'])) return Icons.pool;
    if (_has(l, ['spa', 'massagem'])) return Icons.spa;
    if (_has(l, ['restaurante', 'restaurant'])) return Icons.restaurant;
    if (_has(l, ['academia', 'fitness', 'gym'])) return Icons.fitness_center;
    if (_has(l, ['cafe', 'café', 'manha', 'manhã', 'breakfast'])) return Icons.free_breakfast;
    if (_has(l, ['cama', 'king', 'queen', 'bed'])) return Icons.king_bed;
    if (_has(l, ['estacionamento', 'vaga', 'garagem', 'parking'])) return Icons.local_parking;
    if (_has(l, ['bar'])) return Icons.local_bar;
    if (_has(l, ['frigobar'])) return Icons.kitchen;
    if (_has(l, ['banheira'])) return Icons.bathtub;
    if (_has(l, ['banheiro'])) return Icons.bathtub;
    if (_has(l, ['varanda', 'sacada'])) return Icons.deck;
    if (_has(l, ['cofre', 'safe'])) return Icons.lock;
    if (_has(l, ['secador'])) return Icons.air;
    if (_has(l, ['salao', 'salão', 'evento'])) return Icons.event;
    return Icons.check_circle_outline;
  }

  bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

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