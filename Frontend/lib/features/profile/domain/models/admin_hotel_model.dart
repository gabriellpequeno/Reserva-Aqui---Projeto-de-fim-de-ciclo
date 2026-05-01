import 'admin_account_status.dart';

/// Representação de um hotel na visão do admin (listagem `/admin/hotels`).
class AdminHotelModel {
  final String id;
  final String nome;
  final String emailResponsavel;
  final String? capaUrl;
  final AdminAccountStatus status;
  final int? totalQuartos;
  final DateTime criadoEm;

  const AdminHotelModel({
    required this.id,
    required this.nome,
    required this.emailResponsavel,
    required this.capaUrl,
    required this.status,
    required this.totalQuartos,
    required this.criadoEm,
  });

  factory AdminHotelModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedCriadoEm;
    try {
      parsedCriadoEm = DateTime.parse(json['criadoEm'] as String);
    } catch (_) {
      parsedCriadoEm = DateTime.now();
    }

    return AdminHotelModel(
      id: json['id'] as String,
      nome: (json['nome'] as String?) ?? '',
      emailResponsavel: (json['emailResponsavel'] as String?) ?? '',
      capaUrl: json['capaUrl'] as String?,
      status: AdminAccountStatus.fromString(json['status'] as String?),
      totalQuartos: json['totalQuartos'] as int?,
      criadoEm: parsedCriadoEm,
    );
  }

  AdminHotelModel copyWith({AdminAccountStatus? status}) {
    return AdminHotelModel(
      id: id,
      nome: nome,
      emailResponsavel: emailResponsavel,
      capaUrl: capaUrl,
      status: status ?? this.status,
      totalQuartos: totalQuartos,
      criadoEm: criadoEm,
    );
  }
}
