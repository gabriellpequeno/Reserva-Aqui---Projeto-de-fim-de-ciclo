import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/pagamento_fake_model.dart';

enum PaymentSheetResult { paid, cancelled }

class PaymentResumo {
  final String nomeHotel;
  final String datas;      // "10/06 → 15/06"
  final double valorTotal;

  const PaymentResumo({
    required this.nomeHotel,
    required this.datas,
    required this.valorTotal,
  });
}

/// Resultado de submit: sucesso `true`, ou mensagem de erro específica.
class SubmitOutcome {
  final bool ok;
  final String? errorMessage;
  const SubmitOutcome.success()           : ok = true,  errorMessage = null;
  const SubmitOutcome.failure(this.errorMessage) : ok = false;
}

/// Callback chamado ao clicar "Pagar". Retorna `SubmitOutcome` — em caso de
/// falha, mensagem é exibida no sheet; sheet só fecha em caso de sucesso.
typedef PaymentSubmit = Future<SubmitOutcome> Function(PaymentMethod method);

/// Callback chamado ao clicar "Cancelar". Retorna `SubmitOutcome`.
typedef CancelSubmit  = Future<SubmitOutcome> Function();

/// Abre o modal fake de pagamento. Não é dismissível — força o usuário a
/// escolher entre Pagar e Cancelar, evitando reservas em limbo.
///
/// Retorna o resultado; `null` se, por algum motivo, o sheet for fechado sem
/// decisão (não deveria acontecer com `isDismissible: false`).
Future<PaymentSheetResult?> showPaymentBottomSheet({
  required BuildContext context,
  required PaymentResumo resumo,
  required PaymentSubmit onPay,
  required CancelSubmit onCancel,
}) {
  return showModalBottomSheet<PaymentSheetResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PaymentSheet(
      resumo: resumo,
      onPay: onPay,
      onCancel: onCancel,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  final PaymentResumo resumo;
  final PaymentSubmit onPay;
  final CancelSubmit  onCancel;

  const _PaymentSheet({
    required this.resumo,
    required this.onPay,
    required this.onCancel,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  PaymentMethod? _selected;
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _handlePay() async {
    if (_selected == null) return;
    setState(() { _submitting = true; _errorMessage = null; });

    final outcome = await widget.onPay(_selected!);
    if (!mounted) return;

    if (outcome.ok) {
      Navigator.of(context).pop(PaymentSheetResult.paid);
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = outcome.errorMessage ?? 'Não foi possível concluir o pagamento. Tente novamente.';
      });
    }
  }

  Future<void> _handleCancel() async {
    setState(() { _submitting = true; _errorMessage = null; });
    final outcome = await widget.onCancel();
    if (!mounted) return;

    if (outcome.ok) {
      Navigator.of(context).pop(PaymentSheetResult.cancelled);
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = outcome.errorMessage ?? 'Não foi possível cancelar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.of(context).viewInsets;

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaPadding.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle decorativo
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Pagamento',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.resumo.nomeHotel,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                Text(
                  widget.resumo.datas,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 14),

                _resumoValor(widget.resumo.valorTotal),
                const SizedBox(height: 16),

                const Text(
                  'Forma de pagamento',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ..._methodTiles(),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12),
                  ),
                ],

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_selected == null || _submitting) ? null : _handlePay,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Pagar', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumoValor(double valor) {
    return Container(
      width: double.infinity,
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
            'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
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
                  child: Text(
                    m.label,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Radio<PaymentMethod>(
                  value: m,
                  groupValue: _selected,
                  onChanged: _submitting ? null : (v) => setState(() => _selected = v),
                  activeColor: AppColors.primary,
                ),
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
}
