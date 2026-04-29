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
  // Busca dados do hotel (descrição, foto de capa, avaliações) em paralelo para
  // popular a seção do anfitrião sem bloqueio adicional
  Future<void> loadRoom(String hotelId, String quartoId) async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final dio = ref.read(dioProvider);

      // Carregar quarto e dados do hotel em paralelo — falha individual não bloqueia
      final results = await Future.wait([
        dio.get<Map<String, dynamic>>('/hotel/$hotelId/quartos/$quartoId'),
        _loadHotelConfiguracao(dio, hotelId),
        _loadHotelRating(dio, hotelId),
        _loadHotelCoverUrl(dio, hotelId),
      ], eagerError: false);

      final roomResponse = results[0] as dynamic;
      final hotelConfig  = results[1] as Map<String, dynamic>?;
      final hotelRating  = results[2] as double;
      final hotelCover   = results[3] as String;

      final data      = roomResponse.data!['data'] as Map<String, dynamic>;
      final categoria = data['categoria'] as Map<String, dynamic>? ?? {};
      final itens     = categoria['itens'] as List<dynamic>? ?? [];
      debugPrint('[roomDetailsNotifier] itens recebidos: ${itens.length} — $itens');

      // Extrair categoriaId diretamente para incluir no mesmo copyWith
      final categoriaId = (categoria['id'] as int?) ?? 0;
      final room        = _mapJsonToRoom(data, categoria, hotelConfig, hotelRating, hotelCover);

      state = state.copyWith(room: room, categoriaId: categoriaId, isLoading: false);
    } catch (error) {
      debugPrint('[roomDetailsNotifier] Erro ao carregar detalhes do quarto: $error');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  // Carrega descrição, cidade e uf do hotel via configuração
  Future<Map<String, dynamic>?> _loadHotelConfiguracao(dynamic dio, String hotelId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/$hotelId/configuracao');
      return response.data?['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[roomDetailsNotifier] Configuração do hotel indisponível: $e');
      return null;
    }
  }

  // Calcula nota média do hotel a partir das avaliações
  Future<double> _loadHotelRating(dynamic dio, String hotelId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/$hotelId/avaliacoes');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      if (items.isEmpty) return 0.0;
      final total = items
          .map((i) => _parsePrice((i as Map<String, dynamic>)['nota_total']))
          .reduce((a, b) => a + b);
      return total / items.length;
    } catch (e) {
      debugPrint('[roomDetailsNotifier] Avaliações do hotel indisponíveis: $e');
      return 0.0;
    }
  }

  // Busca a URL da primeira foto de capa do hotel
  // Endpoint fora do prefixo /api/v1 — constrói URL absoluta a partir do serverRoot
  Future<String> _loadHotelCoverUrl(dynamic dio, String hotelId) async {
    try {
      final baseUri    = Uri.parse(dio.options.baseUrl as String);
      final serverRoot = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';
      final response   = await dio.get<Map<String, dynamic>>(
        '$serverRoot/api/uploads/hotels/$hotelId/cover',
      );
      final fotos = (response.data?['fotos'] as List<dynamic>?) ?? [];
      if (fotos.isEmpty) return '';
      return '$serverRoot${(fotos.first as Map<String, dynamic>)['url'] as String}';
    } catch (e) {
      debugPrint('[roomDetailsNotifier] Foto de capa do hotel indisponível: $e');
      return '';
    }
  }

  Room _mapJsonToRoom(
    Map<String, dynamic> data,
    Map<String, dynamic> categoria,
    Map<String, dynamic>? hotelConfig,
    double hotelRating,
    String hotelCoverUrl,
  ) {
    final itens      = (categoria['itens'] as List<dynamic>? ?? []);
    final ratingStr  = hotelRating > 0
        ? hotelRating.toStringAsFixed(1).replaceAll('.', ',')
        : '—';
    final hotelDescricao = hotelConfig?['descricao'] as String? ?? '';

    return Room(
      id:          (data['quarto_id'] ?? 0).toString(),
      hotelId:     data['hotel_id'] as String? ?? '',
      title:       categoria['nome'] as String? ?? '',
      hotelName:   data['nome_hotel'] as String? ?? '',
      destination: '${data['cidade'] ?? ''}, ${data['uf'] ?? ''}',
      description: data['descricao'] as String? ?? categoria['nome'] as String? ?? '',
      imageUrls:   _parseImageUrls(data),
      rating:      '5,0',
      amenities:   _parseAmenities(itens),
      price:       _parsePrice(data['valor_diaria']),
      host: Host(
        name:     data['nome_hotel'] as String? ?? '',
        bio:      hotelDescricao,
        imageUrl: hotelCoverUrl,
        rating:   ratingStr,
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
