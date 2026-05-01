import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Enum de status ────────────────────────────────────────────────────────
enum TicketStatus { aguardo, aprovado, hospedado, cancelado, finalizado }

// ─── Tema de cores por status ──────────────────────────────────────────────
class TicketStatusTheme {
  final Color cardBackground;
  final Color badgeColor;
  final String label;

  const TicketStatusTheme({
    required this.cardBackground,
    required this.badgeColor,
    required this.label,
  });

  static TicketStatusTheme of(TicketStatus status) {
    switch (status) {
      case TicketStatus.aguardo:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFFDDBB4),
          badgeColor: AppColors.secondary,
          label: 'Em Breve',
        );
      case TicketStatus.aprovado:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFB8D4F0),
          badgeColor: AppColors.primary,
          label: 'Em Andamento',
        );
      case TicketStatus.hospedado:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFA8E6A3),
          badgeColor: Color(0xFF16A026),
          label: 'Hospedado',
        );
      case TicketStatus.cancelado:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFF5A0A0),
          badgeColor: Color(0xFFEF2828),
          label: 'Cancelado',
        );
      case TicketStatus.finalizado:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFE0E0E0),
          badgeColor: Color(0xFF828282),
          label: 'Finalizado',
        );
    }
  }
}

// ─── Model ─────────────────────────────────────────────────────────────────
class Ticket {
  final String id;
  final String hotelId;
  final int? quartoId;
  final String hotelName;
  final String roomType;
  final String address;
  final DateTime checkIn;
  final DateTime checkOut;
  final String checkInTime;
  final String checkOutTime;
  final int guestCount;
  final TicketStatus status;
  final String? imageUrl;
  final double subtotal;
  final double discounts;
  final double taxes;
  final double total;

  const Ticket({
    required this.id,
    required this.hotelId,
    this.quartoId,
    required this.hotelName,
    required this.roomType,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.guestCount,
    required this.status,
    this.imageUrl,
    required this.subtotal,
    required this.discounts,
    required this.taxes,
    required this.total,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final checkin = DateTime.tryParse(json['data_checkin']?.toString() ?? '') ?? DateTime.now();
    final checkout = DateTime.tryParse(json['data_checkout']?.toString() ?? '') ?? DateTime.now();
    final total = _parseDouble(json['valor_total']);
    final numHospedes = json['num_hospedes'] is int
        ? json['num_hospedes'] as int
        : int.tryParse(json['num_hospedes']?.toString() ?? '') ?? 1;

    return Ticket(
      id: json['reserva_tenant_id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      quartoId: null,
      hotelName: json['nome_hotel']?.toString() ?? '',
      roomType: json['tipo_quarto']?.toString() ?? '',
      address: '—',
      checkIn: checkin,
      checkOut: checkout,
      checkInTime: '—',
      checkOutTime: '—',
      guestCount: numHospedes,
      status: _mapStatus(json['status']?.toString() ?? '', checkin),
      imageUrl: null,
      subtotal: total,
      discounts: 0.0,
      taxes: 0.0,
      total: total,
    );
  }

  Ticket copyWith({String? imageUrl}) => Ticket(
        id: id,
        hotelId: hotelId,
        quartoId: quartoId,
        hotelName: hotelName,
        roomType: roomType,
        address: address,
        checkIn: checkIn,
        checkOut: checkOut,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        guestCount: guestCount,
        status: status,
        imageUrl: imageUrl ?? this.imageUrl,
        subtotal: subtotal,
        discounts: discounts,
        taxes: taxes,
        total: total,
      );

  static TicketStatus _mapStatus(String status, DateTime checkin) {
    if (status == 'SOLICITADA' || status == 'AGUARDANDO_PAGAMENTO') {
      return TicketStatus.aguardo;
    }
    if (status == 'APROVADA') {
      return DateTime.now().isAfter(checkin)
          ? TicketStatus.hospedado
          : TicketStatus.aprovado;
    }
    if (status == 'CONCLUIDA') return TicketStatus.finalizado;
    if (status == 'CANCELADA') return TicketStatus.cancelado;
    return TicketStatus.aguardo;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String get formattedCheckIn =>
      '${checkIn.day.toString().padLeft(2, '0')}/${checkIn.month.toString().padLeft(2, '0')}';

  String get formattedCheckOut =>
      '${checkOut.day.toString().padLeft(2, '0')}/${checkOut.month.toString().padLeft(2, '0')}';

  String get dateRange => '$formattedCheckIn - $formattedCheckOut';

  String get fullCheckIn {
    final weekdays = [
      'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado', 'domingo',
    ];
    final day = weekdays[checkIn.weekday - 1];
    return '${checkIn.day.toString().padLeft(2, '0')}/${checkIn.month.toString().padLeft(2, '0')}/${checkIn.year}, $day';
  }

  String get fullCheckOut {
    final weekdays = [
      'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado', 'domingo',
    ];
    final day = weekdays[checkOut.weekday - 1];
    return '${checkOut.day.toString().padLeft(2, '0')}/${checkOut.month.toString().padLeft(2, '0')}/${checkOut.year}, $day';
  }
}
