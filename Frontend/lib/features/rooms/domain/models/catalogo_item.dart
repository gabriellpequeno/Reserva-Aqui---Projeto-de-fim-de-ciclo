class CatalogoItemModel {
  final int id;
  final String nome;
  final String categoria;

  const CatalogoItemModel({
    required this.id,
    required this.nome,
    required this.categoria,
  });

  factory CatalogoItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogoItemModel(
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
    );
  }
}
