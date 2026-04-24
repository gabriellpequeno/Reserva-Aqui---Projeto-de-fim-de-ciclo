class RegisterRequest {
  final String nome;
  final String cpf;       // normalizado: só dígitos (11 chars)
  final String telefone;  // normalizado: só dígitos
  final String email;
  final String senha;

  const RegisterRequest({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.senha,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'cpf': cpf,
    'telefone': telefone,
    'email': email,
    'senha': senha,
  };
}
