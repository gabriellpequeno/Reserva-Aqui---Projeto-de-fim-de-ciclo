import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ApprovalResult { approved, rejected }

/// Resultado de uma ação do sheet: sucesso `true`, ou mensagem de erro específica.
class ApprovalOutcome {
  final bool ok;
  final String? errorMessage;
  const ApprovalOutcome.success()              : ok = true,  errorMessage = null;
  const ApprovalOutcome.failure(this.errorMessage) : ok = false;
}

typedef ApprovalSubmit = Future<ApprovalOutcome> Function();

class ApprovalResumo {
  final String nomeHospede;
  final String datas;       // "10/06 → 15/06"
  final String tipoQuarto;
  final double valorTotal;
  final String statusAtual; // label amigável ("Aguardando pagamento" etc.)

  const ApprovalResumo({
    required this.nomeHospede,
    required this.datas,
    required this.tipoQuarto,
    required this.valorTotal,
    required this.statusAtual,
  });
}

/// Abre o modal de gestão de reserva. Mesmo padrão visual do PaymentBottomSheet:
/// não-dismissível, força o host a decidir entre **Aprovar** (status → APROVADA)
/// ou **Negar** (status → CANCELADA).
Future<ApprovalResult?> showApprovalBottomSheet({
  required BuildContext context,
  required ApprovalResumo resumo,
  required ApprovalSubmit onApprove,
  required ApprovalSubmit onReject,
}) {
  return showModalBottomSheet<ApprovalResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ApprovalSheet(
      resumo: resumo,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class _ApprovalSheet extends StatefulWidget {
  final ApprovalResumo resumo;
  final ApprovalSubmit onApprove;
  final ApprovalSubmit onReject;

  const _ApprovalSheet({
    required this.resumo,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends State<_ApprovalSheet> {
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _handleApprove() async {
    setState(() { _submitting = true; _errorMessage = null; });
    final outcome = await widget.onApprove();
    if (!mounted) return;
    if (outcome.ok) {
      Navigator.of(context).pop(ApprovalResult.approved);
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = outcome.errorMessage ?? 'Não foi possível aprovar. Tente novamente.';
      });
    }
  }

  Future<void> _handleReject() async {
    setState(() { _submitting = true; _errorMessage = null; });
    final outcome = await widget.onReject();
    if (!mounted) return;
    if (outcome.ok) {
      Navigator.of(context).pop(ApprovalResult.rejected);
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = outcome.errorMessage ?? 'Não foi possível negar. Tente novamente.';
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
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Gestão de reserva',
                  style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.resumo.statusAtual,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 14),

                _infoCard(),
                const SizedBox(height: 14),

                _totalCard(widget.resumo.valorTotal),

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
                        onPressed: _submitting ? null : _handleReject,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC0392B)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text(
                          'Negar',
                          style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _handleApprove,
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
                            : const Text('Aprovar', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Hóspede',  widget.resumo.nomeHospede),
          const SizedBox(height: 6),
          _row('Quarto',   widget.resumo.tipoQuarto),
          const SizedBox(height: 6),
          _row('Datas',    widget.resumo.datas),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _totalCard(double valor) {
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
            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
