/// Estado do perfil do admin autenticado (consumido pela AdminProfilePage/EditAdminProfilePage).
class AdminProfileState {
  final String nome;
  final String email;
  final String? telefone;
  final String? departamento;
  final List<String>? permissoes;

  const AdminProfileState({
    required this.nome,
    required this.email,
    this.telefone,
    this.departamento,
    this.permissoes,
  });

  factory AdminProfileState.fromJson(Map<String, dynamic> json) {
    return AdminProfileState(
      nome: (json['nome_completo'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      telefone: json['numero_celular'] as String?,
      departamento: json['departamento'] as String?,
      permissoes: (json['permissoes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  AdminProfileState copyWith({
    String? nome,
    String? email,
    String? telefone,
    String? departamento,
    List<String>? permissoes,
  }) {
    return AdminProfileState(
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      departamento: departamento ?? this.departamento,
      permissoes: permissoes ?? this.permissoes,
    );
  }
}
