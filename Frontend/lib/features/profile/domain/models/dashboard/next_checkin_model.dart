import 'package:flutter/foundation.dart';

class NextCheckinModel {
  final int reservaId;
  final String codigoPublico;
  final String nomeHospede;
  final String? quartoNumero;
  final String? tipoQuarto;
  final DateTime dataCheckin;

  const NextCheckinModel({
    required this.reservaId,
    required this.codigoPublico,
    required this.nomeHospede,
    required this.quartoNumero,
    required this.tipoQuarto,
    required this.dataCheckin,
  });

  /// `fromJson` retorna `null` se `dataCheckin` não puder ser parseada — a page
  /// descarta nulls do array resultante.
  static NextCheckinModel? fromJson(Map<String, dynamic> json) {
    final dataRaw = json['dataCheckin'] as String?;
    DateTime parsed;
    try {
      parsed = DateTime.parse(dataRaw ?? '');
    } catch (_) {
      debugPrint('[NextCheckinModel.fromJson] dataCheckin inválida: $dataRaw — descartando item');
      return null;
    }
    return NextCheckinModel(
      reservaId: (json['reservaId'] as num?)?.toInt() ?? 0,
      codigoPublico: (json['codigoPublico'] as String?) ?? '',
      nomeHospede: (json['nomeHospede'] as String?) ?? 'Hóspede',
      quartoNumero: json['quartoNumero'] as String?,
      tipoQuarto: json['tipoQuarto'] as String?,
      dataCheckin: parsed,
    );
  }
}
