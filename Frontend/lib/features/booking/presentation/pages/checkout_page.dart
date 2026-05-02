import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../notifiers/checkout_notifier.dart';
import '../../../tickets/presentation/notifiers/tickets_notifier.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final String hotelId;
  final int categoriaId;
  final int quartoId;

  const CheckoutPage({
    super.key,
    required this.hotelId,
    required this.categoriaId,
    required this.quartoId,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numHospedes = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(checkoutNotifierProvider.notifier)
          .loadData(widget.hotelId, widget.categoriaId, widget.quartoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutNotifierProvider);

    // Navegar para /tickets após reserva criada com sucesso
    ref.listen(checkoutNotifierProvider, (prev, next) {
      if (!next.reservaCreated) return;
      if (prev?.reservaCreated == true) return;
      ref.read(ticketsNotifierProvider.notifier).reload();
      context.go('/tickets');
    });

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: state.isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null && state.categoria == null
                    ? _buildErrorState(state.errorMessage!)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: Column(
                          children: [
                            if (state.errorMessage != null)
                              _buildErrorBanner(state.errorMessage!),
                            _buildMainCard(context, state),
                            const SizedBox(height: 16),
                            _buildFinancialCard(state),
                            if (state.politicas != null) ...[
                              const SizedBox(height: 16),
                              _buildPoliciesCard(state),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Error state (carregamento inicial) ────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref
                  .read(checkoutNotifierProvider.notifier)
                  .loadData(widget.hotelId, widget.categoriaId, widget.quartoId),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF2828).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF2828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFEF2828), fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => ref.read(checkoutNotifierProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: Color(0xFFEF2828), size: 18),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

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

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
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

  Widget _buildMainCard(BuildContext context, CheckoutState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSection(state),
          _buildInfoRow(
            leftLabel: 'Check-in',
            leftValue: state.politicas?.horarioCheckin ?? '—',
            rightLabel: 'Check-out',
            rightValue: state.politicas?.horarioCheckout ?? '—',
          ),
          _buildGuestRow(),
          _buildInfoRow(
            leftLabel: 'Quarto',
            leftValue: state.categoria?.nome ?? '—',
            rightLabel: 'Capacidade',
            rightValue: '${state.categoria?.capacidadePessoas ?? '—'} pessoa(s)',
            isLast: true,
          ),
          _buildFinalizeButton(context, state),
        ],
      ),
    );
  }

  Widget _buildDateSection(CheckoutState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.categoria?.nome ?? 'Carregando...',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w700,
              height: 1.67,
            ),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            label: _formatDate(_checkInDate, 'Check-In'),
            hasValue: _checkInDate != null,
            onTap: () => _pickDate(isCheckIn: true),
          ),
          const SizedBox(height: 8),
          _buildDateField(
            label: _formatDate(_checkOutDate, 'Check-Out'),
            hasValue: _checkOutDate != null,
            onTap: () => _pickDate(isCheckIn: false),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 0.5, color: Color(0xFFE6E6E6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hóspedes',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontFamily: 'Stack Sans Text',
              fontWeight: FontWeight.w700,
              height: 1.67,
            ),
          ),
          Row(
            children: [
              _buildGuestButton(
                icon: Icons.remove,
                onTap: () {
                  if (_numHospedes > 1) setState(() => _numHospedes--);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_numHospedes',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildGuestButton(
                icon: Icons.add,
                onTap: () {
                  final max = ref
                          .read(checkoutNotifierProvider)
                          .categoria
                          ?.capacidadePessoas ??
                      99;
                  if (_numHospedes < max) setState(() => _numHospedes++);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
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
                      height: 1.67)),
              Text(leftValue,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontFamily: 'Stack Sans Text',
                      fontWeight: FontWeight.w300,
                      height: 1.67)),
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
                      height: 1.67)),
              Text(rightValue,
                  style: TextStyle(
                      color: rightValueColor ?? AppColors.primary,
                      fontSize: 12,
                      fontFamily: 'Stack Sans Text',
                      fontWeight: FontWeight.w300,
                      height: 1.67)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton(BuildContext context, CheckoutState state) {
    final canConfirm =
        _checkInDate != null && _checkOutDate != null && !state.isConfirming;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton(
          onPressed: canConfirm ? () => _onConfirm() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: state.isConfirming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
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

  Widget _buildFinancialCard(CheckoutState state) {
    final preco = state.valorDiaria ?? state.categoria?.preco ?? 0.0;
    final dias = (_checkInDate != null && _checkOutDate != null)
        ? _checkOutDate!.difference(_checkInDate!).inDays
        : 0;
    final subtotal = preco * dias;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildFinancialRow(
            'Diária',
            'R\$${preco.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildFinancialRow(
            'Noites',
            '$dias',
          ),
          const SizedBox(height: 10),
          _buildFinancialRow(
            'Total',
            'R\$${subtotal.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
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
                height: 1.40)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Stack Sans Text',
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                height: 1.40)),
      ],
    );
  }

  // ── Card de políticas ─────────────────────────────────────────────────────

  Widget _buildPoliciesCard(CheckoutState state) {
    final p = state.politicas!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Políticas do Hotel',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontFamily: 'Stack Sans Headline',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (p.politicaCancelamento != null)
            _buildPolicyItem(Icons.cancel_outlined, p.politicaCancelamento!),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkInDate ?? now)
        : (_checkOutDate ??
            (_checkInDate ?? now).add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.secondary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkInDate = picked;
        if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
          _checkOutDate = null;
        }
      } else {
        _checkOutDate = picked;
      }
    });
  }

  void _onConfirm() {
    ref.read(checkoutNotifierProvider.notifier).confirm(
          hotelId: widget.hotelId,
          categoriaId: widget.categoriaId,
          quartoId: widget.quartoId,
          checkin: _checkInDate!,
          checkout: _checkOutDate!,
          numHospedes: _numHospedes,
        );
  }

  String _formatDate(DateTime? date, String placeholder) {
    if (date == null) return placeholder;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDateField({
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : const Color(0x3F182541),
            ),
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue
                      ? AppColors.primary
                      : const Color(0x7F182541),
                  fontSize: 12,
                  fontFamily: 'Stack Sans Text',
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
