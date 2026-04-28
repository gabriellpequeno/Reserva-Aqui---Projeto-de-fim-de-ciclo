import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/hotel_details.dart';
import 'hotel_details_state.dart';

class HotelDetailsNotifier extends Notifier<HotelDetailsState> {
  @override
  HotelDetailsState build() {
    return const HotelDetailsState();
  }

  Future<void> loadHotel(String hotelId) async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final dio = ref.read(dioProvider);

      // Disparar 5 futures em paralelo com tratamento individual de cada um
      final futures = <Future<dynamic>>[
        _loadConfiguracao(dio, hotelId),
        _loadCatalogo(dio, hotelId),
        _loadCategorias(dio, hotelId),
        _loadAvaliacoes(dio, hotelId),
        _loadFotos(dio, hotelId),
      ];

      final results = await Future.wait(futures, eagerError: false);

      final configuracao = results[0] as Map<String, dynamic>?;
      final comodidades = results[1] as List<ComodidadeHotelModel>;
      final categorias = results[2] as List<CategoriaHotelModel>;
      final avaliacoes = results[3] as List<AvaliacaoHotelModel>;
      final fotos = results[4] as List<String>;

      final notaMedia = avaliacoes.isNotEmpty
          ? avaliacoes.map((a) => a.notaTotal).reduce((a, b) => a + b) / avaliacoes.length
          : 0.0;

      state = state.copyWith(
        nome: configuracao?['nome_hotel'] as String?,
        descricao: configuracao?['descricao'] as String?,
        cidade: configuracao?['cidade'] as String?,
        uf: configuracao?['uf'] as String?,
        coverUrls: fotos,
        comodidades: comodidades,
        categorias: categorias,
        avaliacoes: avaliacoes,
        notaMedia: notaMedia,
        politicas: configuracao != null ? PoliticasHotelModel.fromJson(configuracao) : null,
        isLoading: false,
      );
    } catch (error) {
      debugPrint('[hotelDetailsNotifier] Erro ao carregar detalhes do hotel: $error');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  // Todos os endpoints retornam { data: ... } — extraímos sempre o campo 'data'

  // Carrega configuração, nome, descrição e políticas
  Future<Map<String, dynamic>?> _loadConfiguracao(
    dynamic dio,
    String hotelId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/configuracao',
      );
      final body = response.data as Map<String, dynamic>?;
      debugPrint('[hotelDetailsNotifier] Configuração carregada');
      return body?['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[hotelDetailsNotifier] Erro ao carregar configuração: $e');
      return null;
    }
  }

  // Carrega comodidades/catálogo
  Future<List<ComodidadeHotelModel>> _loadCatalogo(
    dynamic dio,
    String hotelId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/catalogo',
      );
      final body = response.data as Map<String, dynamic>?;
      final items = (body?['data'] as List<dynamic>?) ?? [];
      final comodidades = items
          .map((i) => ComodidadeHotelModel.fromJson(i as Map<String, dynamic>))
          .toList();
      debugPrint('[hotelDetailsNotifier] Catálogo carregado: ${comodidades.length} itens');
      return comodidades;
    } catch (e) {
      debugPrint('[hotelDetailsNotifier] Erro ao carregar catálogo: $e');
      return [];
    }
  }

  // Carrega categorias de quarto
  Future<List<CategoriaHotelModel>> _loadCategorias(
    dynamic dio,
    String hotelId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/categorias',
      );
      final body = response.data as Map<String, dynamic>?;
      final items = (body?['data'] as List<dynamic>?) ?? [];
      final categorias = items
          .map((i) => CategoriaHotelModel.fromJson(i as Map<String, dynamic>))
          .toList();
      debugPrint('[hotelDetailsNotifier] Categorias carregadas: ${categorias.length}');
      return categorias;
    } catch (e) {
      debugPrint('[hotelDetailsNotifier] Erro ao carregar categorias: $e');
      return [];
    }
  }

  // Carrega avaliações
  Future<List<AvaliacaoHotelModel>> _loadAvaliacoes(
    dynamic dio,
    String hotelId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/avaliacoes',
      );
      final body = response.data as Map<String, dynamic>?;
      final items = (body?['data'] as List<dynamic>?) ?? [];
      final avaliacoes = items
          .map((i) => AvaliacaoHotelModel.fromJson(i as Map<String, dynamic>))
          .toList();
      debugPrint('[hotelDetailsNotifier] Avaliações carregadas: ${avaliacoes.length}');
      return avaliacoes;
    } catch (e) {
      debugPrint('[hotelDetailsNotifier] Erro ao carregar avaliações: $e');
      return [];
    }
  }

  // Endpoint: GET /api/uploads/hotels/:id/cover (prefixo /api, não /api/v1)
  // Resposta: { fotos: [{ id, url: '/api/uploads/hotels/:id/cover/:fotoId', ... }] }
  Future<List<String>> _loadFotos(
    dynamic dio,
    String hotelId,
  ) async {
    try {
      final baseUri = Uri.parse(dio.options.baseUrl as String);
      final serverRoot = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';

      final response = await dio.get<Map<String, dynamic>>(
        '$serverRoot/api/uploads/hotels/$hotelId/cover',
      );

      final fotos = (response.data?['fotos'] as List<dynamic>?) ?? [];
      final urls = fotos
          .map((f) => '$serverRoot${(f as Map<String, dynamic>)['url'] as String}')
          .toList();
      debugPrint('[hotelDetailsNotifier] Fotos carregadas: ${urls.length}');
      return urls;
    } catch (e) {
      debugPrint('[hotelDetailsNotifier] Fotos não disponíveis (fallback): $e');
      return [];
    }
  }
}

final hotelDetailsNotifierProvider = NotifierProvider<HotelDetailsNotifier, HotelDetailsState>(
  HotelDetailsNotifier.new,
);
