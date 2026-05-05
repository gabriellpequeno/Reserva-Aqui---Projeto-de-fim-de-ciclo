import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/booking_service.dart';
import '../../domain/models/pagamento_fake_model.dart';

/// Página pública de pagamento — deep-link do tipo
/// `/pagamento/:codigoPublico/:pagamentoId`, enviada via WhatsApp + email
/// para guests que reservaram pelo bot. Mesma UI do PaymentBottomSheet
/// (PIX / CC / CD), mas sem botão Cancelar e com timer regressivo.
class WhatsappPaymentPage extends ConsumerStatefulWidget {
  final String codigoPublico;
  final int pagamentoId;

  const WhatsappPaymentPage({
    super.key,
    required this.codigoPublico,
    required this.pagamentoId,
  });

  @override
  ConsumerState<WhatsappPaymentPage> createState() => _WhatsappPaymentPageState();
}

class _WhatsappPaymentPageState extends ConsumerState<WhatsappPaymentPage> {
  PagamentoFakeModel? _pag;
  PaymentMethod? _selected;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Timer? _pollTimer;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOnce);
    // Poll a cada 10s — status pode mudar por expiração (job backend) ou por
    // confirmação em outra aba.
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
    // Tick a cada 1s só pra atualizar o contador no UI
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recalcRemaining());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    await _refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    await ref.read(bookingServiceProvider).fetchPagamento(
      codigoPublico: widget.codigoPublico,
      pagamentoId:   widget.pagamentoId,
      onSuccess: (p) { if (mounted) setState(() { _pag = p; _recalcRemaining(); _error = null; }); },
      onError:   (e) { if (mounted) setState(() => _error = e); },
    );
  }

  void _recalcRemaining() {
    final exp = _pag?.expiresAt;
    if (exp == null) { _remaining = Duration.zero; return; }
    final diff = exp.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _pagar() async {
    if (_selected == null || _pag == null) return;
    setState(() { _submitting = true; _error = null; });
    bool ok = false;
    await ref.read(bookingServiceProvider).confirmarPagamento(
      codigoPublico: widget.codigoPublico,
      pagamentoId:   widget.pagamentoId,
      metodo:        _selected!,
      onSuccess: (p) { _pag = p; ok = true; },
      onError:   (e) { _error = e; },
    );
    if (mounted) setState(() => _submitting = false);
    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pagamento da reserva'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pag == null
              ? _errorState()
              : _buildBody(),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error ?? 'Pagamento não encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _refresh, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final p = _pag!;

    if (p.status == 'APROVADO') return _approvedOverlay();
    if (p.status == 'CANCELADO' || _remaining == Duration.zero) return _expiredOverlay();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timerCard(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text(
                  'R\$ ${p.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escolha a forma de pagamento',
            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._methodTiles(),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected == null || _submitting) ? null : _pagar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Pagar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerCard() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    final label = h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final low = _remaining.inMinutes < 5;
    final bg  = low ? const Color(0xFFFDE8E8) : Colors.white;
    final fg  = low ? const Color(0xFFC0392B) : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tempo restante: $label',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _methodTiles() {
    return PaymentMethod.values.map((m) {
      final selected = _selected == m;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: _submitting ? null : () => setState(() => _selected = m),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: selected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            ),
            child: Row(
              children: [
                Icon(_iconFor(m), size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(m.label,
                      style: TextStyle(color: AppColors.primary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ),
                if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.pix:           return Icons.pix;
      case PaymentMethod.cartaoCredito: return Icons.credit_card;
      case PaymentMethod.cartaoDebito:  return Icons.account_balance_wallet_outlined;
    }
  }

  Widget _approvedOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E7A1E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF1E7A1E), size: 52),
            ),
            const SizedBox(height: 16),
            const Text('Pagamento confirmado!',
                style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Enviamos o ticket da sua reserva para o email cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiredOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off_outlined, size: 64, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text('Link expirado',
                style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'O prazo para pagamento desta reserva foi atingido e o link foi cancelado. '
              'Se ainda quiser reservar, inicie um novo pedido.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
