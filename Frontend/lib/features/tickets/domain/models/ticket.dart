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
          badgeColor: AppColors.secondary, // #EC6725
          label: 'Em Breve',
        );
      case TicketStatus.aprovado:
        return const TicketStatusTheme(
          cardBackground: Color(0xFFB8D4F0),
          badgeColor: AppColors.primary, // #182541
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
  final String hotelName;
  final String roomType;
  final String address;
  final DateTime checkIn;
  final DateTime checkOut;
  final String checkInTime;
  final String checkOutTime;
  final int guestCount;
  final TicketStatus status;
  final String imageUrl;
  final double subtotal;
  final double discounts;
  final double taxes;
  final double total;

  const Ticket({
    required this.id,
    required this.hotelName,
    required this.roomType,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.guestCount,
    required this.status,
    required this.imageUrl,
    required this.subtotal,
    required this.discounts,
    required this.taxes,
    required this.total,
  });

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

// ─── Mocks ─────────────────────────────────────────────────────────────────
final List<Ticket> mockTickets = [
  Ticket(
    id: '000000001',
    hotelName: 'Grand Hotel Budapest',
    roomType: 'Standard',
    address: 'Rua dos Bobos, nº 0',
    checkIn: DateTime(2026, 9, 10),
    checkOut: DateTime(2026, 9, 15),
    checkInTime: '13:00',
    checkOutTime: '19:00',
    guestCount: 3,
    status: TicketStatus.aguardo,
    imageUrl: 'lib/assets/images/home_page.jpeg',
    subtotal: 190.98,
    discounts: 20.00,
    taxes: 19.00,
    total: 189.98,
  ),
  Ticket(
    id: '000000002',
    hotelName: 'Grand Hotel Budapest',
    roomType: 'Standard',
    address: 'Rua dos Bobos, nº 0',
    checkIn: DateTime(2026, 9, 10),
    checkOut: DateTime(2026, 9, 15),
    checkInTime: '13:00',
    checkOutTime: '19:00',
    guestCount: 3,
    status: TicketStatus.aprovado,
    imageUrl: 'lib/assets/images/home_page.jpeg',
    subtotal: 190.98,
    discounts: 20.00,
    taxes: 19.00,
    total: 189.98,
  ),
  Ticket(
    id: '000000003',
    hotelName: 'Grand Hotel Budapest',
    roomType: 'Standard',
    address: 'Rua dos Bobos, nº 0',
    checkIn: DateTime(2026, 9, 10),
    checkOut: DateTime(2026, 9, 15),
    checkInTime: '13:00',
    checkOutTime: '19:00',
    guestCount: 3,
    status: TicketStatus.hospedado,
    imageUrl: 'lib/assets/images/home_page.jpeg',
    subtotal: 190.98,
    discounts: 20.00,
    taxes: 19.00,
    total: 189.98,
  ),
  Ticket(
    id: '000000004',
    hotelName: 'Grand Hotel Budapest',
    roomType: 'Standard',
    address: 'Rua dos Bobos, nº 0',
    checkIn: DateTime(2026, 9, 10),
    checkOut: DateTime(2026, 9, 15),
    checkInTime: '13:00',
    checkOutTime: '19:00',
    guestCount: 3,
    status: TicketStatus.cancelado,
    imageUrl: 'lib/assets/images/home_page.jpeg',
    subtotal: 190.98,
    discounts: 20.00,
    taxes: 19.00,
    total: 189.98,
  ),
  Ticket(
    id: '000000005',
    hotelName: 'Grand Hotel Budapest',
    roomType: 'Standard',
    address: 'Rua dos Bobos, nº 0',
    checkIn: DateTime(2026, 9, 10),
    checkOut: DateTime(2026, 9, 15),
    checkInTime: '13:00',
    checkOutTime: '19:00',
    guestCount: 3,
    status: TicketStatus.finalizado,
    imageUrl: 'lib/assets/images/home_page.jpeg',
    subtotal: 190.98,
    discounts: 20.00,
    taxes: 19.00,
    total: 189.98,
  ),
];
