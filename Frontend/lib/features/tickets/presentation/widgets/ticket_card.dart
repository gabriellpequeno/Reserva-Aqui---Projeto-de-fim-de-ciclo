import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;

  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = TicketStatusTheme.of(ticket.status);

    return Column(
      children: [
        // ── Card com ClipPath ──────────────────────────────────────────
        // IntrinsicHeight obrigatório: sem altura definida, o Row com
        // CrossAxisAlignment.stretch colapsa pra 0 quando embrulhado num
        // ClipPath no Flutter Web, deixando o card invisível.
        IntrinsicHeight(
          child: ClipPath(
            clipper: const _TicketClipper(),
            child: Container(
              color: theme.cardBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Lado esquerdo: informações ─────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'Stack Sans Headline',
                              ),
                              children: [
                                TextSpan(
                                  text: ticket.hotelName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (ticket.roomType.isNotEmpty)
                                  TextSpan(
                                    text: ' — ${ticket.roomType}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(
                            label: theme.label,
                            color: theme.badgeColor,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoRow(
                                  icon: Icons.calendar_today,
                                  text: ticket.dateRange,
                                  color: theme.badgeColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _InfoInlineCompact(
                                icon: Icons.person_outline,
                                text: '${ticket.guestCount}',
                                color: theme.badgeColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: ticket.address,
                            color: theme.badgeColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Lado direito: imagem ─────────────────────────
                  SizedBox(
                    width: 99,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: ticket.imageUrl != null
                          ? Image.network(
                              ticket.imageUrl!,
                              width: 99,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(theme),
                            )
                          : _buildImagePlaceholder(theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Botão Detalhes ─────────────────────────────────────────────
        if (ticket.id.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            height: 38,
            child: ElevatedButton(
              onPressed: () => context.push('/tickets/details/${ticket.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Detalhes',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePlaceholder(TicketStatusTheme theme) {
    return Container(
      width: 99,
      color: theme.cardBackground.withValues(alpha: 0.6),
      child: Icon(Icons.hotel, size: 36, color: theme.badgeColor.withValues(alpha: 0.4)),
    );
  }
}

// ─── Badge de status ───────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info compacto sem Flexible — seguro em Row aninhado ──────────────────
class _InfoInlineCompact extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoInlineCompact({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontFamily: 'Stack Sans Text',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Linha de info com ícone ───────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ClipPath: forma de ticket físico ─────────────────────────────────────
class _TicketClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;

  const _TicketClipper({
    this.cornerRadius = 16,
    this.notchRadius = 12,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final midY = size.height / 2;

    // Top-left corner
    path.moveTo(cornerRadius, 0);
    // Borda superior
    path.lineTo(size.width - cornerRadius, 0);
    // Top-right corner
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    // Borda direita — metade de cima
    path.lineTo(size.width, midY - notchRadius);
    // Notch direito (côncavo — vai para dentro)
    path.arcToPoint(
      Offset(size.width, midY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Borda direita — metade de baixo
    path.lineTo(size.width, size.height - cornerRadius);
    // Bottom-right corner
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );
    // Borda inferior
    path.lineTo(cornerRadius, size.height);
    // Bottom-left corner
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    // Borda esquerda — metade de baixo
    path.lineTo(0, midY + notchRadius);
    // Notch esquerdo (côncavo — vai para dentro)
    path.arcToPoint(
      Offset(0, midY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Borda esquerda — metade de cima
    path.lineTo(0, cornerRadius);
    // Top-left corner
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.cornerRadius != cornerRadius || old.notchRadius != notchRadius;
}