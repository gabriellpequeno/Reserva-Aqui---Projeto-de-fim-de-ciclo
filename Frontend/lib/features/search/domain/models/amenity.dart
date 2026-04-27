class Amenity {
  final int catalogoId;
  final String nome;
  final String categoria;
  final int quantidade;

  Amenity({
    required this.catalogoId,
    required this.nome,
    required this.categoria,
    required this.quantidade,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Amenity &&
          runtimeType == other.runtimeType &&
          catalogoId == other.catalogoId;

  @override
  int get hashCode => catalogoId.hashCode;
}
