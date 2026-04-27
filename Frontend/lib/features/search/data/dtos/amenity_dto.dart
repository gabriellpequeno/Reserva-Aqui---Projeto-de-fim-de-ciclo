class AmenityDto {
  final int catalogoId;
  final String nome;
  final String categoria;
  final int quantidade;

  AmenityDto({
    required this.catalogoId,
    required this.nome,
    required this.categoria,
    required this.quantidade,
  });

  factory AmenityDto.fromJson(Map<String, dynamic> json) {
    return AmenityDto(
      catalogoId: json['catalogo_id'] as int,
      nome: json['nome'] as String,
      categoria: json['categoria'] as String,
      quantidade: json['quantidade'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'catalogo_id': catalogoId,
    'nome': nome,
    'categoria': categoria,
    'quantidade': quantidade,
  };
}
