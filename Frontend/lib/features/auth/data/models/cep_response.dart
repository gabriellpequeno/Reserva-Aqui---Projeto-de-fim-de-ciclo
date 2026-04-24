class CepResponse {
  final String? logradouro;
  final String? bairro;
  final String? localidade;
  final String? uf;
  final bool erro;

  CepResponse({
    this.logradouro,
    this.bairro,
    this.localidade,
    this.uf,
    this.erro = false,
  });

  factory CepResponse.fromJson(Map<String, dynamic> json) {
    return CepResponse(
      logradouro: json['logradouro'] as String?,
      bairro: json['bairro'] as String?,
      localidade: json['localidade'] as String?,
      uf: json['uf'] as String?,
      erro: json['erro'] == true || json['erro'] == 'true',
    );
  }
}
