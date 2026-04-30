import '../../domain/models/room_category_card.dart';
import '../../domain/models/reserva_hotel.dart';
import '../../../rooms/domain/models/hotel_details.dart';

enum FiltroDisponibilidade { todos, disponiveis, indisponiveis }

class MyRoomsState {
  final List<RoomCategoryCardModel> cards;
  final List<CategoriaHotelModel> categorias;
  final List<ReservaHotelModel> reservas;
  final Map<int, Set<DateTime>> diasIndisponiveisPorCategoria;
  final String busca;
  final FiltroDisponibilidade filtroDisponibilidade;
  final bool loading;
  final bool deleteInProgress;
  final bool reservaInProgress;
  final String? error;

  const MyRoomsState({
    this.cards = const [],
    this.categorias = const [],
    this.reservas = const [],
    this.diasIndisponiveisPorCategoria = const {},
    this.busca = '',
    this.filtroDisponibilidade = FiltroDisponibilidade.todos,
    this.loading = false,
    this.deleteInProgress = false,
    this.reservaInProgress = false,
    this.error,
  });

  List<RoomCategoryCardModel> get cardsFiltrados {
    var resultado = cards;

    if (busca.isNotEmpty) {
      final query = busca.toLowerCase();
      resultado = resultado
          .where((c) => c.nomeCategoria.toLowerCase().contains(query))
          .toList();
    }

    switch (filtroDisponibilidade) {
      case FiltroDisponibilidade.disponiveis:
        resultado = resultado.where((c) => c.disponivel).toList();
      case FiltroDisponibilidade.indisponiveis:
        resultado = resultado.where((c) => !c.disponivel).toList();
      case FiltroDisponibilidade.todos:
        break;
    }

    return resultado;
  }

  MyRoomsState copyWith({
    List<RoomCategoryCardModel>? cards,
    List<CategoriaHotelModel>? categorias,
    List<ReservaHotelModel>? reservas,
    Map<int, Set<DateTime>>? diasIndisponiveisPorCategoria,
    String? busca,
    FiltroDisponibilidade? filtroDisponibilidade,
    bool? loading,
    bool? deleteInProgress,
    bool? reservaInProgress,
    String? error,
    bool clearError = false,
  }) {
    return MyRoomsState(
      cards: cards ?? this.cards,
      categorias: categorias ?? this.categorias,
      reservas: reservas ?? this.reservas,
      diasIndisponiveisPorCategoria:
          diasIndisponiveisPorCategoria ?? this.diasIndisponiveisPorCategoria,
      busca: busca ?? this.busca,
      filtroDisponibilidade: filtroDisponibilidade ?? this.filtroDisponibilidade,
      loading: loading ?? this.loading,
      deleteInProgress: deleteInProgress ?? this.deleteInProgress,
      reservaInProgress: reservaInProgress ?? this.reservaInProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
