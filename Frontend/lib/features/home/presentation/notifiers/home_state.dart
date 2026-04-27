import '../../../rooms/domain/models/room.dart';

class HomeState {
  final List<Room> rooms;
  final bool isLoading;
  final bool hasError;

  const HomeState({
    this.rooms = const [],
    this.isLoading = false,
    this.hasError = false,
  });

  HomeState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    bool? hasError,
  }) {
    return HomeState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}