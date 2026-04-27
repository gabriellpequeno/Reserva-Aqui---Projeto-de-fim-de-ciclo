import 'package:dio/dio.dart';

class UploadService {
  final Dio dio;

  UploadService({required this.dio});

  Future<String?> fetchFirstRoomPhotoUrl(String hotelId, int quartoId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/uploads/hotels/$hotelId/rooms/$quartoId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final fotos = (data['fotos'] as List<dynamic>?) ?? [];

        if (fotos.isEmpty) {
          return null;
        }

        // Encontra foto com menor 'ordem' (padrão 0, ordem crescente)
        fotos.sort((a, b) {
          final aMap = a as Map<String, dynamic>;
          final bMap = b as Map<String, dynamic>;
          final aOrdem = (aMap['ordem'] as num?)?.toInt() ?? 999;
          final bOrdem = (bMap['ordem'] as num?)?.toInt() ?? 999;
          return aOrdem.compareTo(bOrdem);
        });

        final firstPhoto = fotos.first as Map<String, dynamic>;
        return firstPhoto['url'] as String?;
      }

      return null;
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }
}
