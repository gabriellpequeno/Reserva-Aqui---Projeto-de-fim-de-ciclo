class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final String tipo;
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isRead = false,
    this.tipo = '',
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? timestamp,
    bool? isRead,
    String? tipo,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      tipo: tipo ?? this.tipo,
      payload: payload ?? this.payload,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String? ?? '';
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] as String? ?? _titleFromTipo(tipo),
      subtitle: json['subtitle'] as String? ?? json['body'] as String? ?? '',
      timestamp: DateTime.tryParse(
            (json['timestamp'] ?? json['created_at']) as String? ?? '',
          ) ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? json['lida'] as bool? ?? false,
      tipo: tipo,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'tipo': tipo,
        'payload': payload,
      };

  static String _titleFromTipo(String tipo) {
    return switch (tipo) {
      'NOVA_RESERVA' => 'Nova Reserva',
      'APROVACAO_RESERVA' => 'Reserva Aprovada',
      'PAGAMENTO_CONFIRMADO' => 'Pagamento Confirmado',
      'RESERVA_CANCELADA' => 'Reserva Cancelada',
      'MENSAGEM_CHAT' => 'Nova Mensagem',
      _ => 'Notificação',
    };
  }
}
