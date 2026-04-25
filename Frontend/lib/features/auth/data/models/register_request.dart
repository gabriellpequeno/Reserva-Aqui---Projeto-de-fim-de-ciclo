class RegisterRequest {
  final String nome;
  final String cpf;            // normalizado: só dígitos (11 chars)
  final String telefone;       // normalizado: só dígitos
  final String email;
  final String senha;
  final String dataNascimento; // formato dd/mm/aaaa

  const RegisterRequest({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.senha,
    required this.dataNascimento,
  });

  Map<String, dynamic> toJson() => {
    'nome_completo': nome,
    'cpf': cpf,
    'numero_celular': telefone,
    'email': email,
    'senha': senha,
    'data_nascimento': dataNascimento,
  };
}
