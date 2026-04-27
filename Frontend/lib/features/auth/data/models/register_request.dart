class RegisterRequest {
  final String nomeCompleto;
  final String cpf;
  final String numeroCelular;
  final String email;
  final String senha;
  final String dataNascimento;

  const RegisterRequest({
    required this.nomeCompleto,
    required this.cpf,
    required this.numeroCelular,
    required this.email,
    required this.senha,
    required this.dataNascimento,
  });

  Map<String, dynamic> toJson() => {
    'nome_completo': nomeCompleto,
    'cpf': cpf,
    'numero_celular': numeroCelular,
    'email': email,
    'senha': senha,
    'data_nascimento': dataNascimento,
  };
}
