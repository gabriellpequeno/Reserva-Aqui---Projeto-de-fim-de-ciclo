import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ticket.dart';

class TicketDetailsPage extends ConsumerWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = mockTickets.firstWhere(
      (t) => t.id == ticketId,
      orElse: () => mockTickets.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                children: [
                  _buildMainCard(ticket),
                  const SizedBox(height: 16),
                  _buildFinancialCard(ticket),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.pop(),
                    context: context,
                  ),
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 28,
                  ),
                  _headerButton(
                    icon: Icons.notifications_none,
                    onTap: () => context.go('/notifications'),
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Reserva',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.79,
        height: 45.79,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.37),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.17),
            width: 0.62,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Card principal ────────────────────────────────────────────────────────
  Widget _buildMainCard(Ticket ticket) {
    final theme = TicketStatusTheme.of(ticket.status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Endereço e datas completas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.address,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w700,
                    height: 1.67,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check-in: ${ticket.fullCheckIn}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Check-out: ${ticket.fullCheckOut}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
              ],
            ),
          ),

          _infoRow('Chegada', ticket.checkInTime, 'Saída', ticket.checkOutTime),
          _infoRow(
            'Ticket ID', ticket.id,
            'Status', theme.label,
            rightValueColor: theme.badgeColor,
          ),
          _infoRow(
            'Hóspedes', '${ticket.guestCount} adultos',
            'Quarto', ticket.roomType,
            isLast: false,
          ),

          // Seção Detalhes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFFE6E6E6), thickness: 0.5),
                const SizedBox(height: 8),
                const Text(
                  'Detalhes',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w700,
                    height: 1.67,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket.roomType} — ${ticket.hotelName}. '
                  'Quarto com vista panorâmica, ar-condicionado, '
                  'café da manhã incluso e Wi-Fi de alta velocidade.',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String leftLabel,
    String leftValue,
    String rightLabel,
    String rightValue, {
    Color? rightValueColor,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(width: 0.5, color: Color(0xFFE6E6E6)),
          bottom: isLast
              ? const BorderSide(width: 0.5, color: Color(0xFFE6E6E6))
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w700,
                    height: 1.67,
                  )),
              Text(leftValue,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w300,
                    height: 1.67,
                  )),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w700,
                    height: 1.67,
                  )),
              Text(rightValue,
                  style: TextStyle(
                    color: rightValueColor ?? AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w300,
                    height: 1.67,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card financeiro ───────────────────────────────────────────────────────
  Widget _buildFinancialCard(Ticket ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _financialRow('Subtotal', 'R\$${ticket.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _financialRow('Descontos', '-R\$${ticket.discounts.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _financialRow('Taxas', 'R\$${ticket.taxes.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _financialRow('Total', 'R\$${ticket.total.toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isTotal = false}) {
    final color = isTotal ? AppColors.secondary : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w700,
              height: 1.40,
            )),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              height: 1.40,
            )),
      ],
    );
  }
}
