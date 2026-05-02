import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Mock de dados ─────────────────────────────────────────────────────────
class _BookingMock {
  final String locationName;
  final String checkInTime;
  final String checkOutTime;
  final String ticketId;
  final String status;
  final int guestCount;
  final String roomType;
  final double subtotal;
  final double discounts;
  final double taxes;
  final double total;

  const _BookingMock({
    required this.locationName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.ticketId,
    required this.status,
    required this.guestCount,
    required this.roomType,
    required this.subtotal,
    required this.discounts,
    required this.taxes,
    required this.total,
  });
}

const _mockBooking = _BookingMock(
  locationName: 'Rua dos Bobos, nº 0',
  checkInTime: '13:00',
  checkOutTime: '19:00',
  ticketId: '000000000',
  status: 'Em Breve',
  guestCount: 3,
  roomType: 'Standard',
  subtotal: 190.98,
  discounts: 20.00,
  taxes: 19.00,
  total: 189.98,
);

// ─── Página ────────────────────────────────────────────────────────────────
class CheckoutPage extends ConsumerStatefulWidget {
  final String roomId;

  const CheckoutPage({super.key, required this.roomId});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkInDate ?? now)
        : (_checkOutDate ?? (_checkInDate ?? now).add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkInDate = picked;
        // Se checkout já selecionado e for antes do novo checkin, limpa
        if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
          _checkOutDate = null;
        }
      } else {
        _checkOutDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHigh,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                children: [
                  _buildMainCard(context),
                  const SizedBox(height: 16),
                  _buildFinancialCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, String placeholder) {
    if (date == null) return placeholder;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                  _buildHeaderButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.pop(),
                  ),
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 28,
                  ),
                  _buildHeaderButton(
                    icon: Icons.notifications_none,
                    onTap: () => context.go('/notifications'),
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
                  height: 1.20,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
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
  Widget _buildMainCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSection(),
          _buildInfoRow(
            leftLabel: 'Chegada',
            leftValue: _mockBooking.checkInTime,
            rightLabel: 'Saída',
            rightValue: _mockBooking.checkOutTime,
          ),
          _buildInfoRow(
            leftLabel: 'Ticket ID',
            leftValue: _mockBooking.ticketId,
            rightLabel: 'Status',
            rightValue: _mockBooking.status,
            rightValueColor: AppColors.secondary,
          ),
          _buildInfoRow(
            leftLabel: 'Hóspedes',
            leftValue: '${_mockBooking.guestCount} adultos',
            rightLabel: 'Quarto',
            rightValue: _mockBooking.roomType,
            isLast: true,
          ),
          _buildFinalizeButton(context),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mockBooking.locationName,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w700,
              height: 1.67,
            ),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            label: _formatDate(_checkInDate, 'Check-In Date'),
            hasValue: _checkInDate != null,
            onTap: () => _pickDate(isCheckIn: true),
          ),
          const SizedBox(height: 8),
          _buildDateField(
            label: _formatDate(_checkOutDate, 'Check-Out Date'),
            hasValue: _checkOutDate != null,
            onTap: () => _pickDate(isCheckIn: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: hasValue
                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                  : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: AppColors.secondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    Color? rightValueColor,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 0.5, color: colorScheme.outline),
          bottom: isLast
              ? BorderSide(width: 0.5, color: colorScheme.outline)
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
              Text(
                leftLabel,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight: FontWeight.w700,
                  height: 1.67,
                ),
              ),
              Text(
                leftValue,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight: FontWeight.w300,
                  height: 1.67,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rightLabel,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight: FontWeight.w700,
                  height: 1.67,
                ),
              ),
              Text(
                rightValue,
                style: TextStyle(
                  color: rightValueColor ?? colorScheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight: FontWeight.w300,
                  height: 1.67,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reserva registrada com sucesso.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/tickets');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: const Text(
            'Finalizar Reserva',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Stack Sans Headline',
              fontWeight: FontWeight.w700,
              height: 1.71,
            ),
          ),
        ),
      ),
    );
  }

  // ── Card financeiro ───────────────────────────────────────────────────────
  Widget _buildFinancialCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildFinancialRow(
            'Subtotal',
            'R\$${_mockBooking.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildFinancialRow(
            'Descontos',
            '-R\$${_mockBooking.discounts.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildFinancialRow(
            'Taxas',
            'R\$${_mockBooking.taxes.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildFinancialRow(
            'Total',
            'R\$${_mockBooking.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isTotal ? AppColors.secondary : colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'Stack Sans Text',
            fontWeight: FontWeight.w700,
            height: 1.40,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'Stack Sans Text',
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            height: 1.40,
          ),
        ),
      ],
    );
  }
}
