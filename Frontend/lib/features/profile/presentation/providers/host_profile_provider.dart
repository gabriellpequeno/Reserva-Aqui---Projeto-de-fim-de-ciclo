import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/Hotel.dart';
import '../../../../core/network/dio_client.dart';

class HostProfileState {
  final Map<String, dynamic> hotel;
  final List<Map<String, dynamic>> fotos;

  const HostProfileState({required this.hotel, required this.fotos});
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
}

final hostProfileProvider =
    AsyncNotifierProvider<HostProfileNotifier, HostProfileState>(() {
      return HostProfileNotifier();
    });
