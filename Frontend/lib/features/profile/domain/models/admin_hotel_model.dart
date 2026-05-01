import 'admin_account_status.dart';

/// Representação de um hotel na visão do admin (listagem `/admin/hotels`).
class AdminHotelModel {
  final String id;
  final String nome;
  final String emailResponsavel;
  final String telefone;
  final String? descricao;
  final String cep;
  final String uf;
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? complemento;
  final String? capaUrl;
  final AdminAccountStatus status;
  final int? totalQuartos;
  final DateTime criadoEm;

  const AdminHotelModel({
    required this.id,
    required this.nome,
    required this.emailResponsavel,
    required this.telefone,
    required this.descricao,
    required this.cep,
    required this.uf,
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    required this.complemento,
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
      telefone: (json['telefone'] as String?) ?? '',
      descricao: json['descricao'] as String?,
      cep: (json['cep'] as String?) ?? '',
      uf: (json['uf'] as String?) ?? '',
      cidade: (json['cidade'] as String?) ?? '',
      bairro: (json['bairro'] as String?) ?? '',
      rua: (json['rua'] as String?) ?? '',
      numero: (json['numero'] as String?) ?? '',
      complemento: json['complemento'] as String?,
      capaUrl: json['capaUrl'] as String?,
      status: AdminAccountStatus.fromString(json['status'] as String?),
      totalQuartos: json['totalQuartos'] as int?,
      criadoEm: parsedCriadoEm,
    );
  }

  AdminHotelModel copyWith({
    String? nome,
    String? emailResponsavel,
    String? telefone,
    String? descricao,
    String? cep,
    String? uf,
    String? cidade,
    String? bairro,
    String? rua,
    String? numero,
    String? complemento,
    AdminAccountStatus? status,
  }) {
    return AdminHotelModel(
      id: id,
      nome: nome ?? this.nome,
      emailResponsavel: emailResponsavel ?? this.emailResponsavel,
      telefone: telefone ?? this.telefone,
      descricao: descricao ?? this.descricao,
      cep: cep ?? this.cep,
      uf: uf ?? this.uf,
      cidade: cidade ?? this.cidade,
      bairro: bairro ?? this.bairro,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      capaUrl: capaUrl,
      status: status ?? this.status,
      totalQuartos: totalQuartos,
      criadoEm: criadoEm,
    );
  }
}
