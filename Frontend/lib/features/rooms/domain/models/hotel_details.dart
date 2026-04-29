class ComodidadeHotelModel {
  final int id;
  final String nome;
  final String categoria;

  ComodidadeHotelModel({
    required this.id,
    required this.nome,
    required this.categoria,
  });

  factory ComodidadeHotelModel.fromJson(Map<String, dynamic> json) {
    return ComodidadeHotelModel(
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
    );
  }
}

class CategoriaHotelModel {
  final int id;
  final String nome;
  final int capacidadePessoas;
  final double preco;
  final List<ComodidadeHotelModel> itens;
  // ID do primeiro quarto disponível da categoria — usado para navegar ao room_details
  final int? primeiroQuartoId;

  CategoriaHotelModel({
    required this.id,
    required this.nome,
    required this.capacidadePessoas,
    required this.preco,
    required this.itens,
    this.primeiroQuartoId,
  });

  factory CategoriaHotelModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'] as List<dynamic>? ?? [];
    return CategoriaHotelModel(
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      capacidadePessoas: json['capacidade_pessoas'] as int? ?? 0,
      preco: _parsePrice(json['valor_diaria']),
      primeiroQuartoId: json['primeiro_quarto_id'] as int?,
      itens: itensRaw
          .map((i) => ComodidadeHotelModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}

class AvaliacaoHotelModel {
  final int id;
  final double notaTotal;
  final String? comentario;
  final String nomeUsuario;
  final String timeAgo;

  AvaliacaoHotelModel({
    required this.id,
    required this.notaTotal,
    this.comentario,
    required this.nomeUsuario,
    required this.timeAgo,
  });

  factory AvaliacaoHotelModel.fromJson(Map<String, dynamic> json) {
    return AvaliacaoHotelModel(
      id: json['id'] as int? ?? 0,
      notaTotal: _parsePrice(json['nota_total'] ?? json['nota_media']),
      comentario: json['comentario'] as String?,
      nomeUsuario: json['nome_usuario'] as String? ?? 'Usuário Anônimo',
      timeAgo: _calculateTimeAgo(json['criado_em']),
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  static String _calculateTimeAgo(dynamic date) {
    if (date == null) return 'recentemente';
    try {
      final createdAt = DateTime.parse(date.toString());
      final now = DateTime.now();
      final diff = now.difference(createdAt);

      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()} ano${diff.inDays > 365 ? 's' : ''} atrás';
      } else if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()} mês${diff.inDays > 30 ? 'es' : ''} atrás';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} dia${diff.inDays > 1 ? 's' : ''} atrás';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h atrás';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}min atrás';
      }
      return 'agora';
    } catch (e) {
      return 'recentemente';
    }
  }
}

class PoliticasHotelModel {
  final String horarioCheckin;
  final String horarioCheckout;
  final String? politicaCancelamento;
  final List<String>? regras;

  PoliticasHotelModel({
    required this.horarioCheckin,
    required this.horarioCheckout,
    this.politicaCancelamento,
    this.regras,
  });

  factory PoliticasHotelModel.fromJson(Map<String, dynamic> json) {
    return PoliticasHotelModel(
      horarioCheckin: json['horario_checkin'] as String? ?? '14:00',
      horarioCheckout: json['horario_checkout'] as String? ?? '12:00',
      politicaCancelamento: json['politica_cancelamento'] as String?,
      regras: (json['regras'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}
