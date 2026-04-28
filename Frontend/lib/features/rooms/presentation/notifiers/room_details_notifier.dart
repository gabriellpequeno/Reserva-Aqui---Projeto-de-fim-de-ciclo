import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../notifiers/room_details_state.dart';
import '../../domain/models/room.dart';

class RoomDetailsNotifier extends Notifier<RoomDetailsState> {
  @override
  RoomDetailsState build() {
    return const RoomDetailsState();
  }

  // Carregamento: chama GET /api/hotel/:hotelId/quartos/:quartoId e atualiza estado
  Future<void> loadRoom(String hotelId, String quartoId) async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/quartos/$quartoId',
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final categoria = data['categoria'] as Map<String, dynamic>? ?? {};
      final itens = categoria['itens'] as List<dynamic>? ?? [];
      debugPrint('[roomDetailsNotifier] itens recebidos: ${itens.length} — $itens');

      // Extrair categoriaId diretamente para incluir no mesmo copyWith
      final categoriaId = (categoria['id'] as int?) ?? 0;
      final room = _mapJsonToRoom(data, categoria);

      state = state.copyWith(room: room, categoriaId: categoriaId, isLoading: false);
    } catch (error) {
      debugPrint('[roomDetailsNotifier] Erro ao carregar detalhes do quarto: $error');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  Room _mapJsonToRoom(Map<String, dynamic> data, Map<String, dynamic> categoria) {
    final itens = (categoria['itens'] as List<dynamic>? ?? []);

    return Room(
      id: (data['quarto_id'] ?? 0).toString(),
      hotelId: data['hotel_id'] as String? ?? '',
      title: categoria['nome'] as String? ?? '',
      hotelName: data['nome_hotel'] as String? ?? '',
      destination: '${data['cidade'] ?? ''}, ${data['uf'] ?? ''}',
      description: data['descricao'] as String? ?? categoria['nome'] as String? ?? '',
      imageUrls: _parseImageUrls(data),
      rating: '5,0',
      amenities: _parseAmenities(itens),
      price: _parsePrice(data['valor_diaria']),
      host: Host(
        name: data['nome_hotel'] as String? ?? '',
        bio: '',
        imageUrl: '',
        rating: '0,0',
      ),
    );
  }

  // Monta lista de URLs de imagem com fotos placeholder para teste do carrossel
  List<String> _parseImageUrls(Map<String, dynamic> data) {
    final fotos = data['fotos'] as List<dynamic>?;
    if (fotos != null && fotos.isNotEmpty) {
      return fotos.map((f) => f as String).toList();
    }
    // Placeholder com 4 fotos variadas para validar funcionamento do carrossel
    return [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=800',
      'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=800',
      'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=800',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=800',
    ];
  }

  List<Amenity> _parseAmenities(List<dynamic> itens) {
    return itens.map((item) {
      final data = item as Map<String, dynamic>;
      final nome = data['nome'] as String? ?? '';
      return Amenity(nome, _iconForItemName(nome));
    }).toList();
  }

  // Mapeamento de ícones: converte nome do item do catálogo para IconData padronizado
  IconData _iconForItemName(String nome) {
    final lower = nome.toLowerCase();
    if (lower.contains('wi-fi') || lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi;
    }
    if (lower.contains('ar-condicionado') || lower.contains('ar condicionado') || lower.contains('climatiz')) {
      return Icons.air;
    }
    if (lower.contains('tv') || lower.contains('televisão') || lower.contains('televisao')) {
      return Icons.tv;
    }
    if (lower.contains('frigobar') || lower.contains('frigorífico') || lower.contains('minibar')) {
      return Icons.kitchen;
    }
    if (lower.contains('cofre')) {
      return Icons.lock_outline;
    }
    if (lower.contains('king')) {
      return Icons.king_bed_outlined;
    }
    if (lower.contains('cama') || lower.contains('queen')) {
      return Icons.bed_outlined;
    }
    if (lower.contains('banheiro') || lower.contains('chuveiro') || lower.contains('ducha')) {
      return Icons.shower_outlined;
    }
    if (lower.contains('varanda') || lower.contains('terraço') || lower.contains('sacada')) {
      return Icons.balcony_outlined;
    }
    if (lower.contains('piscina')) {
      return Icons.pool;
    }
    if (lower.contains('spa') || lower.contains('hidromassagem')) {
      return Icons.hot_tub_outlined;
    }
    if (lower.contains('academia') || lower.contains('fitness') || lower.contains('ginásio')) {
      return Icons.fitness_center;
    }
    if (lower.contains('estacionamento') || lower.contains('garagem')) {
      return Icons.local_parking;
    }
    if (lower.contains('café') || lower.contains('cafe') || lower.contains('restaurante') || lower.contains('refeição')) {
      return Icons.restaurant;
    }
    return Icons.hotel;
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}

final roomDetailsNotifierProvider =
    NotifierProvider<RoomDetailsNotifier, RoomDetailsState>(RoomDetailsNotifier.new);
