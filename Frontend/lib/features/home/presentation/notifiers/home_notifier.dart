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

      final rooms = await Future.wait((response.data ?? []).map((json) async {
        final data = json as Map<String, dynamic>;
        final hotelId = data['hotelId'] as String? ?? '';
        final quartoId = data['roomId'] as String? ?? '';
        final rawImageUrl = data['imageUrl'] as String? ?? '';

        String imageUrl;
        if (rawImageUrl.isNotEmpty) {
          imageUrl = rawImageUrl.startsWith('/')
              ? '$backendHost$rawImageUrl'
              : rawImageUrl;
        } else {
          imageUrl = await _fetchFirstRoomPhotoUrl(hotelId, quartoId);
        }

        return Room(
          id: quartoId,
          hotelId: hotelId,
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
      }));

      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (error) {
      debugPrint('[homeNotifier] Erro ao carregar recomendações: $error');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  static const _fallbackImages = [
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&q=80',
    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
    'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800&q=80',
    'https://images.unsplash.com/photo-1596436889106-be35e843f974?w=800&q=80',
  ];

  Future<String> _fetchFirstRoomPhotoUrl(String hotelId, String quartoId) async {
    if (hotelId.isEmpty || quartoId.isEmpty) return _fallbackFor(quartoId);
    try {
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>(
        '/uploads/hotels/$hotelId/rooms/$quartoId',
      );
      final fotos = res.data?['fotos'] as List<dynamic>? ?? [];
      if (fotos.isEmpty) return _fallbackFor(quartoId);
      final fotoId = (fotos.first as Map<String, dynamic>)['id'] as String? ?? '';
      if (fotoId.isEmpty) return _fallbackFor(quartoId);
      return '$backendHost/api/v1/uploads/hotels/$hotelId/rooms/$quartoId/$fotoId';
    } catch (_) {
      return _fallbackFor(quartoId);
    }
  }

  String _fallbackFor(String quartoId) {
    final index = quartoId.hashCode.abs() % _fallbackImages.length;
    return _fallbackImages[index];
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