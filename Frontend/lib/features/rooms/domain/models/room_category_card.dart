class RoomCategoryCardModel {
  final int categoriaId;
  final String nomeCategoria;
  final String? descricao;
  final int totalUnidades;
  final List<int> quartoIds;
  final String? fotoUrl;
  final double? valorBase;
  final bool disponivel;
  // Preenchida apenas em cards inativos — próxima reserva ativa associada a essa categoria
  final DateTime? proximaReservaAtiva;

  const RoomCategoryCardModel({
    required this.categoriaId,
    required this.nomeCategoria,
    this.descricao,
    required this.totalUnidades,
    required this.quartoIds,
    this.fotoUrl,
    this.valorBase,
    this.disponivel = true,
    this.proximaReservaAtiva,
  });

  RoomCategoryCardModel copyWith({
    String? fotoUrl,
    double? valorBase,
    String? descricao,
    DateTime? proximaReservaAtiva,
  }) {
    return RoomCategoryCardModel(
      categoriaId: categoriaId,
      nomeCategoria: nomeCategoria,
      descricao: descricao ?? this.descricao,
      totalUnidades: totalUnidades,
      quartoIds: quartoIds,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      valorBase: valorBase ?? this.valorBase,
      disponivel: disponivel,
      proximaReservaAtiva: proximaReservaAtiva ?? this.proximaReservaAtiva,
    );
  }
}
