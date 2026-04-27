class UserProfileModel {
  final String id;
  final String nomeCompleto;
  final String email;
  final String? cpf;
  final String? numeroCelular;
  final String? fotoPerfil;
  final String? dataNascimento;

  const UserProfileModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.cpf,
    this.numeroCelular,
    this.fotoPerfil,
    this.dataNascimento,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      nomeCompleto: json['nome_completo'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String?,
      numeroCelular: json['numero_celular'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      dataNascimento: json['data_nascimento'] as String?,
    );
  }
}
