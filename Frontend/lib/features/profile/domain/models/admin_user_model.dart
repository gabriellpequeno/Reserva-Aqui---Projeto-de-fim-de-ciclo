import 'admin_account_status.dart';

/// Representação de um hóspede na visão do admin (listagem `/admin/users`).
class AdminUserModel {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final AdminAccountStatus status;
  final DateTime criadoEm;

  const AdminUserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.fotoUrl,
    required this.status,
    required this.criadoEm,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedCriadoEm;
    try {
      parsedCriadoEm = DateTime.parse(json['criadoEm'] as String);
    } catch (_) {
      parsedCriadoEm = DateTime.now();
    }

    return AdminUserModel(
      id: json['id'] as String,
      nome: (json['nome'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      telefone: json['telefone'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      status: AdminAccountStatus.fromString(json['status'] as String?),
      criadoEm: parsedCriadoEm,
    );
  }

  AdminUserModel copyWith({AdminAccountStatus? status}) {
    return AdminUserModel(
      id: id,
      nome: nome,
      email: email,
      telefone: telefone,
      fotoUrl: fotoUrl,
      status: status ?? this.status,
      criadoEm: criadoEm,
    );
  }
}
