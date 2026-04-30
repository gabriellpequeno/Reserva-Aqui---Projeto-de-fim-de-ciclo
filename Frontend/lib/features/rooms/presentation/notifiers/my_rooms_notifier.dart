import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/quarto.dart';
import '../../domain/models/room_category_card.dart';
import '../../domain/models/reserva_hotel.dart';
import '../../domain/models/hotel_details.dart';
import '../../domain/services/availability_calculator.dart';
import 'my_rooms_state.dart';

class MyRoomsNotifier extends Notifier<MyRoomsState> {
  @override
  MyRoomsState build() => const MyRoomsState();

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final dio = ref.read(dioProvider);

      final hotelId = await _fetchHotelId(dio);
      if (hotelId == null) {
        state = state.copyWith(
            loading: false, error: 'Sessão expirada. Faça login novamente.');
        return;
      }

      final now = DateTime.now();
      final from = _fmtDate(now);
      final to = _fmtDate(now.add(const Duration(days: 180)));

      final results = await Future.wait(
        [
          _loadQuartos(dio),
          _loadCategorias(dio, hotelId),
          _loadReservas(dio, from, to),
        ],
        eagerError: false,
      );

      final quartos    = results[0] as List<QuartoModel>;
      final categorias = results[1] as List<CategoriaHotelModel>;
      final reservas   = results[2] as List<ReservaHotelModel>;

      final cards = _buildCards(quartos, categorias, reservas);
      final cardsComFoto = await _loadFotos(dio, hotelId, cards);
      final disponibilidade = _calcularDisponibilidade(cardsComFoto, reservas);

      state = state.copyWith(
        cards: cardsComFoto,
        categorias: categorias,
        reservas: reservas,
        diasIndisponiveisPorCategoria: disponibilidade,
        loading: false,
      );
    } catch (e, st) {
      debugPrint('[myRoomsNotifier] Erro ao carregar: $e\n$st');
      state = state.copyWith(
          loading: false,
          error: 'Não foi possível carregar os quartos. Verifique sua conexão e tente novamente.');
    }
  }

  Future<void> refresh() => load();

  void setBusca(String busca) => state = state.copyWith(busca: busca);

  void setFiltro(FiltroDisponibilidade filtro) =>
      state = state.copyWith(filtroDisponibilidade: filtro);

  // ── Deactivate (Desativar) ────────────────────────────────────────────────

  // Retorna {'sucesso': N, 'falha': N}
  Future<Map<String, int>> deativarUnidades(
    int categoriaId,
    int quantidade, {
    required bool permanente,
  }) async {
    final card = state.cards.firstWhere(
        (c) => c.categoriaId == categoriaId && c.disponivel);
    final idsParaDesativar = card.quartoIds.take(quantidade).toList();

    state = state.copyWith(deleteInProgress: true);

    final dio = ref.read(dioProvider);
    int sucesso = 0, falha = 0;
    final now = DateTime.now();

    for (final quartoId in idsParaDesativar) {
      if (permanente) {
        final temReserva = state.reservas.any((r) =>
            r.ativa &&
            r.quartoId == quartoId &&
            r.dataCheckout.isAfter(now));

        if (temReserva) {
          // Não pode deletar — marca como indisponível
          final ok = await _patchDisponivel(dio, quartoId, false);
          if (ok) sucesso++; else falha++;
        } else {
          final ok = await _deleteQuarto(dio, quartoId);
          if (ok) sucesso++; else falha++;
        }
      } else {
        final ok = await _patchDisponivel(dio, quartoId, false);
        if (ok) sucesso++; else falha++;
      }
    }

    await load();
    state = state.copyWith(deleteInProgress: false);
    return {'sucesso': sucesso, 'falha': falha};
  }

  // ── Reactivate (Reativar) ─────────────────────────────────────────────────

  Future<Map<String, int>> reativarUnidades(int categoriaId) async {
    final card = state.cards.firstWhere(
        (c) => c.categoriaId == categoriaId && !c.disponivel);

    state = state.copyWith(deleteInProgress: true);

    final dio = ref.read(dioProvider);
    int sucesso = 0, falha = 0;

    for (final quartoId in card.quartoIds) {
      final ok = await _patchDisponivel(dio, quartoId, true);
      if (ok) sucesso++; else falha++;
    }

    await load();
    state = state.copyWith(deleteInProgress: false);
    return {'sucesso': sucesso, 'falha': falha};
  }

  // ── Delete from inactive card (Remover do card inativo) ───────────────────

  // Retorna null se a exclusão é permitida, ou mensagem de bloqueio.
  // Bloqueio: reservas ativas para os quartos inativos > quartos ativos da mesma categoria.
  String? verificarBloqueioExclusao(int categoriaId) {
    final inativoCard = state.cards.firstWhere(
        (c) => c.categoriaId == categoriaId && !c.disponivel);

    final now = DateTime.now();
    final reservasAtivas = state.reservas
        .where((r) =>
            r.ativa &&
            r.quartoId != null &&
            inativoCard.quartoIds.contains(r.quartoId) &&
            r.dataCheckout.isAfter(now))
        .length;

    if (reservasAtivas == 0) return null;

    final ativoCard = state.cards
        .where((c) => c.categoriaId == categoriaId && c.disponivel)
        .firstOrNull;
    final quartosAtivos = ativoCard?.totalUnidades ?? 0;

    if (reservasAtivas > quartosAtivos) {
      return 'Este quarto possui $reservasAtivas reserva${reservasAtivas != 1 ? 's' : ''} ativa${reservasAtivas != 1 ? 's' : ''} e a categoria conta com apenas $quartosAtivos quarto${quartosAtivos != 1 ? 's' : ''} ativo${quartosAtivos != 1 ? 's' : ''}. Aguarde a conclusão das reservas antes de excluir.';
    }

    return null;
  }

  Future<Map<String, int>> excluirUnidadesInativas(int categoriaId) async {
    final card = state.cards.firstWhere(
        (c) => c.categoriaId == categoriaId && !c.disponivel);

    state = state.copyWith(deleteInProgress: true);

    final dio = ref.read(dioProvider);
    int sucesso = 0, falha = 0;

    for (final quartoId in card.quartoIds) {
      final ok = await _deleteQuarto(dio, quartoId);
      if (ok) sucesso++; else falha++;
    }

    await load();
    state = state.copyWith(deleteInProgress: false);
    return {'sucesso': sucesso, 'falha': falha};
  }

  // ── Manual reservation ────────────────────────────────────────────────────

  Future<String?> criarReservaManual({
    required int categoriaId,
    required DateTime checkin,
    required DateTime checkout,
    required double valorTotal,
  }) async {
    final card = state.cards.firstWhere(
        (c) => c.categoriaId == categoriaId && c.disponivel);
    state = state.copyWith(reservaInProgress: true);

    try {
      final dio = ref.read(dioProvider);

      await dio.post<Map<String, dynamic>>(
        '/hotel/reservas',
        data: {
          'canal_origem': 'BALCAO',
          'tipo_quarto': card.nomeCategoria,
          'num_hospedes': 1,
          'data_checkin': _fmtDate(checkin),
          'data_checkout': _fmtDate(checkout),
          'valor_total': valorTotal,
        },
      );

      await load();
      state = state.copyWith(reservaInProgress: false);
      return null;
    } catch (e) {
      debugPrint('[myRoomsNotifier] Erro ao criar reserva manual: $e');
      state = state.copyWith(reservaInProgress: false);
      return 'Não foi possível criar a reserva. Tente novamente ou entre em contato com o suporte.';
    }
  }

  // ── Helpers: active reservation check ────────────────────────────────────

  bool temReservaAtiva(List<int> quartoIds) {
    final now = DateTime.now();
    return state.reservas.any((r) =>
        r.ativa &&
        r.quartoId != null &&
        quartoIds.contains(r.quartoId) &&
        r.dataCheckout.isAfter(now));
  }

  DateTime? proximaReservaAtiva(List<int> quartoIds) {
    final now = DateTime.now();
    final ativas = state.reservas
        .where((r) =>
            r.ativa &&
            r.quartoId != null &&
            quartoIds.contains(r.quartoId) &&
            r.dataCheckout.isAfter(now))
        .toList();
    if (ativas.isEmpty) return null;
    return ativas
        .map((r) => r.dataCheckin)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<String?> _fetchHotelId(dynamic dio) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/me');
      final data = response.data?['data'] as Map<String, dynamic>?;
      final id = data?['hotel_id'] ?? data?['id'];
      return id?.toString();
    } catch (e) {
      debugPrint('[myRoomsNotifier] Erro ao buscar hotel_id: $e');
      return null;
    }
  }

  Future<List<QuartoModel>> _loadQuartos(dynamic dio) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/quartos');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      return items
          .map((i) => QuartoModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[myRoomsNotifier] Erro ao carregar quartos: $e');
      rethrow;
    }
  }

  Future<List<CategoriaHotelModel>> _loadCategorias(
      dynamic dio, String hotelId) async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>('/hotel/$hotelId/categorias');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      return items
          .map((i) => CategoriaHotelModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[myRoomsNotifier] Erro ao carregar categorias: $e');
      return [];
    }
  }

  Future<List<ReservaHotelModel>> _loadReservas(
      dynamic dio, String from, String to) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/reservas',
        queryParameters: {'data_checkin_from': from, 'data_checkout_to': to},
      );
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      return items
          .map((i) => ReservaHotelModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[myRoomsNotifier] Reservas indisponíveis (não fatal): $e');
      return [];
    }
  }

  // Cria um card por grupo (categoriaId + disponivel).
  // Cards ativos usam apenas quartos disponíveis; inativos usam os indisponíveis.
  List<RoomCategoryCardModel> _buildCards(
    List<QuartoModel> quartos,
    List<CategoriaHotelModel> categorias,
    List<ReservaHotelModel> reservas,
  ) {
    final categoriaMap = {for (final c in categorias) c.id: c};
    final gruposAtivos   = <int, List<QuartoModel>>{};
    final gruposInativos = <int, List<QuartoModel>>{};

    for (final q in quartos) {
      if (q.disponivel) {
        gruposAtivos.putIfAbsent(q.categoriaQuartoId, () => []).add(q);
      } else {
        gruposInativos.putIfAbsent(q.categoriaQuartoId, () => []).add(q);
      }
    }

    final cards = <RoomCategoryCardModel>[];
    final now = DateTime.now();

    for (final entry in gruposAtivos.entries) {
      cards.add(_makeCard(entry.key, entry.value, categoriaMap[entry.key],
          disponivel: true));
    }

    for (final entry in gruposInativos.entries) {
      final quartoIds = entry.value.map((q) => q.id).toList();

      // Próxima reserva ativa para exibição no card inativo
      final ativas = reservas
          .where((r) =>
              r.ativa &&
              r.quartoId != null &&
              quartoIds.contains(r.quartoId) &&
              r.dataCheckout.isAfter(now))
          .toList();
      final proxima = ativas.isNotEmpty
          ? ativas
              .map((r) => r.dataCheckin)
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null;

      cards.add(_makeCard(
        entry.key,
        entry.value,
        categoriaMap[entry.key],
        disponivel: false,
        proximaReservaAtiva: proxima,
      ));
    }

    return cards;
  }

  RoomCategoryCardModel _makeCard(
    int catId,
    List<QuartoModel> unidades,
    CategoriaHotelModel? cat, {
    required bool disponivel,
    DateTime? proximaReservaAtiva,
  }) {
    final valorBase = unidades
        .where((q) => q.valorDiaria != null)
        .map((q) => q.valorDiaria!)
        .fold<double?>(null, (prev, v) => prev == null ? v : (prev + v) / 2);

    return RoomCategoryCardModel(
      categoriaId: catId,
      nomeCategoria: cat?.nome ?? 'Categoria $catId',
      descricao: unidades
          .firstWhere((q) => q.descricao != null,
              orElse: () => unidades.first)
          .descricao,
      totalUnidades: unidades.length,
      quartoIds: unidades.map((q) => q.id).toList(),
      disponivel: disponivel,
      proximaReservaAtiva: proximaReservaAtiva,
      valorBase: valorBase ?? cat?.preco,
    );
  }

  Future<List<RoomCategoryCardModel>> _loadFotos(
    dynamic dio,
    String hotelId,
    List<RoomCategoryCardModel> cards,
  ) async {
    final baseUri = Uri.parse(dio.options.baseUrl as String);
    final serverRoot =
        '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';

    final futures =
        cards.map((card) => _loadFotoCard(dio, serverRoot, hotelId, card));
    final cardsComFoto = await Future.wait(futures, eagerError: false);
    return cardsComFoto.cast<RoomCategoryCardModel>();
  }

  Future<RoomCategoryCardModel> _loadFotoCard(
    dynamic dio,
    String serverRoot,
    String hotelId,
    RoomCategoryCardModel card,
  ) async {
    for (final quartoId in card.quartoIds) {
      try {
        final response = await dio.get<Map<String, dynamic>>(
            '$serverRoot/api/uploads/hotels/$hotelId/rooms/$quartoId');
        final fotos = (response.data?['fotos'] as List<dynamic>?) ?? [];
        if (fotos.isNotEmpty) {
          final url =
              '$serverRoot${(fotos.first as Map<String, dynamic>)['url'] as String}';
          return card.copyWith(fotoUrl: url);
        }
      } catch (_) {}
    }
    return card;
  }

  // Disponibilidade só usa quartos ativos
  Map<int, Set<DateTime>> _calcularDisponibilidade(
    List<RoomCategoryCardModel> cards,
    List<ReservaHotelModel> reservas,
  ) {
    return {
      for (final card in cards.where((c) => c.disponivel))
        card.categoriaId: computeDiasIndisponiveis(
          reservas,
          card.quartoIds,
          card.totalUnidades,
          nomeCategoria: card.nomeCategoria,
        ),
    };
  }

  Future<bool> _patchDisponivel(dynamic dio, int quartoId, bool disponivel) async {
    try {
      await dio.patch<void>(
        '/hotel/quartos/$quartoId',
        data: {'disponivel': disponivel},
      );
      return true;
    } catch (e) {
      debugPrint('[myRoomsNotifier] Falha ao atualizar quarto $quartoId: $e');
      return false;
    }
  }

  Future<bool> _deleteQuarto(dynamic dio, int quartoId) async {
    try {
      await dio.delete<void>('/hotel/quartos/$quartoId');
      return true;
    } catch (e) {
      debugPrint('[myRoomsNotifier] Falha ao deletar quarto $quartoId: $e');
      return false;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final myRoomsNotifierProvider =
    NotifierProvider<MyRoomsNotifier, MyRoomsState>(MyRoomsNotifier.new);
