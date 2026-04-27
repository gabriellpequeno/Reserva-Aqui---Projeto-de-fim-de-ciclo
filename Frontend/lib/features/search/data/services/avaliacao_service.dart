import 'package:dio/dio.dart';
import '../../domain/models/hotel_rating_summary.dart';

class AvaliacaoService {
  final Dio dio;

  AvaliacaoService({required this.dio});

  Future<HotelRatingSummary> fetchHotelRating(String hotelId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/avaliacoes',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final avaliacoes = (data['data'] as List<dynamic>?) ?? [];

        if (avaliacoes.isEmpty) {
          return HotelRatingSummary.empty();
        }

        final notaTotals = avaliacoes.map((a) {
          final aMap = a as Map<String, dynamic>;
          return (aMap['nota_total'] as num?)?.toDouble() ?? 0.0;
        }).toList();

        final average = notaTotals.isNotEmpty
            ? notaTotals.reduce((a, b) => a + b) / notaTotals.length
            : null;

        return HotelRatingSummary(
          average: average,
          count: avaliacoes.length,
        );
      }

      return HotelRatingSummary.empty();
    } on DioException {
      return HotelRatingSummary.empty();
    } catch (e) {
      return HotelRatingSummary.empty();
    }
  }
}
