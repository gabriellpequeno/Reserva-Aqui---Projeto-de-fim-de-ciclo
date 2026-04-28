import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/Hotel.dart';
import '../../../../core/network/dio_client.dart';

class HostProfileState {
  final Map<String, dynamic> hotel;
  final List<Map<String, dynamic>> fotos;

  const HostProfileState({required this.hotel, required this.fotos});

  HostProfileState copyWith({
    Map<String, dynamic>? hotel,
    List<Map<String, dynamic>>? fotos,
  }) {
    return HostProfileState(
      hotel: hotel ?? this.hotel,
      fotos: fotos ?? this.fotos,
    );
  }
}

class HostProfileNotifier extends AsyncNotifier<HostProfileState> {
  @override
  Future<HostProfileState> build() async {
    return _fetchData();
  }

  Future<HostProfileState> _fetchData() async {
    final hotelService = ref.read(hotelServiceProvider);
    final dio = ref.read(dioProvider);

    final completer = Completer<Map<String, dynamic>>();

    await hotelService.getAutenticado(
      onSuccess: (hotel) {
        completer.complete(hotel);
      },
      onError: (message) {
        completer.completeError(Exception(message));
      },
    );

    final hotelData = await completer.future;

    final hotelId = hotelData['hotel_id'] ?? hotelData['id'];
    List<Map<String, dynamic>> fotosData = [];

    if (hotelId != null) {
      try {
        final response = await dio.get('/uploads/hotels/$hotelId/cover');
        if (response.data != null && response.data['fotos'] != null) {
          fotosData = (response.data['fotos'] as List)
              .cast<Map<String, dynamic>>();
        }
      } catch (e) {
        // Falha de fotos não-fatal
      }
    }

    return HostProfileState(hotel: hotelData, fotos: fotosData);
  }

  Future<void> updateProfile(Map<String, dynamic> diff) async {
    if (diff.isEmpty) {
      throw Exception('Nenhuma alteração a salvar.');
    }

    final hotelService = ref.read(hotelServiceProvider);
    final completer = Completer<Map<String, dynamic>>();

    await hotelService.updateMe(
      body: diff,
      onSuccess: (hotel) => completer.complete(hotel),
      onError: (message) => completer.completeError(Exception(message)),
    );

    final updated = await completer.future;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(hotel: updated));
    }
  }

  Future<void> changePassword({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    final hotelService = ref.read(hotelServiceProvider);
    final completer = Completer<void>();

    await hotelService.changePassword(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      confirmarNovaSenha: confirmarNovaSenha,
      onSuccess: () => completer.complete(),
      onError: (message) => completer.completeError(Exception(message)),
    );

    await completer.future;
  }
}

final hostProfileProvider =
    AsyncNotifierProvider<HostProfileNotifier, HostProfileState>(() {
      return HostProfileNotifier();
    });
