class QuartoItem {
  final int catalogoId;
  final String nome;
  final String categoria;
  final int quantidade;

  const QuartoItem({
    required this.catalogoId,
    required this.nome,
    required this.categoria,
    required this.quantidade,
  });

  factory QuartoItem.fromJson(Map<String, dynamic> json) {
    return QuartoItem(
      catalogoId: (json['catalogo_id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      quantidade: (json['quantidade'] as num).toInt(),
    );
  }
}

class SearchRoomResult {
  final int quartoId;
  final String hotelId;
  final String numero;
  final String? descricao;
  final String valorDiaria;
  final List<QuartoItem> itens;
  final String nomeHotel;
  final String cidade;
  final String uf;

  const SearchRoomResult({
    required this.quartoId,
    required this.hotelId,
    required this.numero,
    this.descricao,
    required this.valorDiaria,
    required this.itens,
    required this.nomeHotel,
    required this.cidade,
    required this.uf,
  });

  factory SearchRoomResult.fromJson(Map<String, dynamic> json) {
    final rawItens = json['itens'] as List<dynamic>? ?? [];
    return SearchRoomResult(
      quartoId: (json['quarto_id'] as num).toInt(),
      hotelId: json['hotel_id'] as String,
      numero: json['numero'] as String? ?? '',
      descricao: json['descricao'] as String?,
      valorDiaria: json['valor_diaria']?.toString() ?? '0',
      itens: rawItens
          .map((e) => QuartoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nomeHotel: json['nome_hotel'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
    );
  }
}
