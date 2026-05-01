class QuartoItemModel {
  final int catalogoId;
  final String nome;
  final String categoria;
  final int quantidade;

  const QuartoItemModel({
    required this.catalogoId,
    required this.nome,
    required this.categoria,
    required this.quantidade,
  });

  factory QuartoItemModel.fromJson(Map<String, dynamic> json) {
    return QuartoItemModel(
      catalogoId: json['catalogo_id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      quantidade: json['quantidade'] as int? ?? 1,
    );
  }
}

class QuartoModel {
  final int id;
  final String numero;
  final int categoriaQuartoId;
  final bool disponivel;
  final String? descricao;
  final double? valorDiaria;
  final List<QuartoItemModel> itens;

  const QuartoModel({
    required this.id,
    required this.numero,
    required this.categoriaQuartoId,
    required this.disponivel,
    this.descricao,
    this.valorDiaria,
    this.itens = const [],
  });

  factory QuartoModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'] as List<dynamic>? ?? [];
    return QuartoModel(
      id: json['id'] as int? ?? 0,
      numero: json['numero'] as String? ?? '',
      categoriaQuartoId: json['categoria_quarto_id'] as int? ?? 0,
      disponivel: json['disponivel'] as bool? ?? true,
      descricao: json['descricao'] as String?,
      valorDiaria: _parseDouble(json['valor_diaria']),
      itens: itensRaw
          .map((i) => QuartoItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
