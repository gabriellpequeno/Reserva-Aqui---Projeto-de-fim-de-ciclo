import '../../../rooms/domain/models/room.dart';

// Estado imutável da tela de detalhes: dados do quarto, loading e erro
class RoomDetailsState {
  final Room? room;
  final int categoriaId;
  final bool isLoading;
  final bool hasError;

  const RoomDetailsState({
    this.room,
    this.categoriaId = 0,
    this.isLoading = false,
    this.hasError = false,
  });

  RoomDetailsState copyWith({
    Room? room,
    int? categoriaId,
    bool? isLoading,
    bool? hasError,
  }) {
    return RoomDetailsState(
      room: room ?? this.room,
      categoriaId: categoriaId ?? this.categoriaId,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}
