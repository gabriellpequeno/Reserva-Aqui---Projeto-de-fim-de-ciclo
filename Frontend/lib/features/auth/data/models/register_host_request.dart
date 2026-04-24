class RegisterHostRequest {
  final String nomeHotel;
  final String cnpj;
  final String telefone;
  final String email;
  final String senha;
  final String cep;
  final String uf;
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? complemento;
  final String? descricao;

  const RegisterHostRequest({
    required this.nomeHotel,
    required this.cnpj,
    required this.telefone,
    required this.email,
    required this.senha,
    required this.cep,
    required this.uf,
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    this.complemento,
    this.descricao,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'nome_hotel': nomeHotel,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
      'senha': senha,
      'cep': cep,
      'uf': uf.toUpperCase(),
      'cidade': cidade,
      'bairro': bairro,
      'rua': rua,
      'numero': numero,
    };

    if (complemento != null && complemento!.isNotEmpty) {
      map['complemento'] = complemento!;
    }
    if (descricao != null && descricao!.isNotEmpty) {
      map['descricao'] = descricao!;
    }

    return map;
  }
}
