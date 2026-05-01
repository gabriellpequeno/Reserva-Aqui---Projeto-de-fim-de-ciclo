import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DeleteRoomDialog extends StatefulWidget {
  final String nomeCategoria;
  final int totalUnidades;
  final bool temReservaAtiva;
  final DateTime? proximaReservaAtiva;
  final Future<void> Function(int quantidade, {required bool permanente}) onConfirm;

  const DeleteRoomDialog({
    super.key,
    required this.nomeCategoria,
    required this.totalUnidades,
    required this.temReservaAtiva,
    required this.onConfirm,
    this.proximaReservaAtiva,
  });

  @override
  State<DeleteRoomDialog> createState() => _DeleteRoomDialogState();
}

class _DeleteRoomDialogState extends State<DeleteRoomDialog> {
  // confirm → quantity → tipo → (warning)
  String _step = 'confirm';
  int _quantidade = 1;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'quantity':   return _buildQuantity();
      case 'tipo':       return _buildTipo();
      case 'warning':    return _buildWarning();
      default:           return _buildConfirm();
    }
  }

  // ── Passo 1: Confirmar ────────────────────────────────────────────────────

  Widget _buildConfirm() {
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.secondary, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Desativar unidades',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.nomeCategoria,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.greyText, fontSize: 13),
        ),
        const SizedBox(height: 12),
        const Text(
          'Unidades desativadas não aceitarão novas reservas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.greyText, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildBotoes(
          onVoltar: () => Navigator.of(context).pop(),
          labelVoltar: 'Cancelar',
          onAvancar: () => setState(() => _step = 'quantity'),
          labelAvancar: 'Continuar',
        ),
      ],
    );
  }

  // ── Passo 2: Quantidade ───────────────────────────────────────────────────

  Widget _buildQuantity() {
    return Column(
      key: const ValueKey('quantity'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Quantas unidades?',
            'Total disponível: ${widget.totalUnidades} unidade${widget.totalUnidades != 1 ? 's' : ''}'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Diminuir quantidade',
              child: IconButton(
                onPressed: _quantidade > 1 ? () => setState(() => _quantidade--) : null,
                icon: Icon(Icons.remove_circle_outline,
                    color: _quantidade > 1 ? AppColors.secondary : AppColors.greyText,
                    size: 36),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$_quantidade',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: 'Aumentar quantidade',
              child: IconButton(
                onPressed: _quantidade < widget.totalUnidades
                    ? () => setState(() => _quantidade++)
                    : null,
                icon: Icon(Icons.add_circle_outline,
                    color: _quantidade < widget.totalUnidades
                        ? AppColors.secondary
                        : AppColors.greyText,
                    size: 36),
              ),
            ),
          ],
        ),
        if (_quantidade == widget.totalUnidades) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Todas as unidades serão desativadas.',
              style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildBotoes(
          onVoltar: _loading ? null : () => setState(() => _step = 'confirm'),
          labelVoltar: 'Voltar',
          onAvancar: _loading ? null : () => setState(() => _step = 'tipo'),
          labelAvancar: 'Continuar',
        ),
      ],
    );
  }

  // ── Passo 3: Permanente ou Temporário ─────────────────────────────────────

  Widget _buildTipo() {
    return Column(
      key: const ValueKey('tipo'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Como desativar?', '$_quantidade unidade${_quantidade != 1 ? 's' : ''}'),
        const SizedBox(height: 20),
        _buildOpcaoTipo(
          titulo: 'Temporariamente',
          descricao: 'Unidades ficam indisponíveis. Podem ser reativadas depois.',
          icone: Icons.pause_circle_outline,
          onTap: () => _confirmar(permanente: false),
        ),
        const SizedBox(height: 10),
        _buildOpcaoTipo(
          titulo: 'Permanentemente',
          descricao: 'Unidades sem reservas são excluídas. Com reservas, ficam indisponíveis até a conclusão.',
          icone: Icons.delete_outline,
          cor: Colors.red[600]!,
          onTap: () {
            if (widget.temReservaAtiva) {
              setState(() => _step = 'warning');
            } else {
              _confirmar(permanente: true);
            }
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _loading ? null : () => setState(() => _step = 'quantity'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            minimumSize: const Size(double.infinity, 46),
          ),
          child: const Text('Voltar',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildOpcaoTipo({
    required String titulo,
    required String descricao,
    required IconData icone,
    required VoidCallback onTap,
    Color cor = AppColors.primary,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
          color: cor.withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: cor, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(descricao,
                      style: const TextStyle(
                          color: AppColors.greyText, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Passo 4: Aviso reserva ativa (permanente + com reserva) ──────────────

  Widget _buildWarning() {
    final proxima = widget.proximaReservaAtiva;
    return Column(
      key: const ValueKey('warning'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_busy, color: Colors.orange[700], size: 44),
        const SizedBox(height: 12),
        Text(
          'Reservas em andamento',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          proxima != null
              ? 'Próxima reserva ativa: ${_fmtData(proxima)}.\n\nA unidade ficará indisponível até a conclusão ou cancelamento de todas as reservas.'
              : 'Existem reservas ativas para esta unidade.\n\nEla ficará indisponível até a conclusão ou cancelamento de todas as reservas.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.greyText, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildBotoes(
          onVoltar: _loading ? null : () => setState(() => _step = 'tipo'),
          labelVoltar: 'Voltar',
          onAvancar: _loading ? null : () => _confirmar(permanente: true),
          labelAvancar: 'Entendido, continuar',
          corAvancar: Colors.orange[700]!,
        ),
      ],
    );
  }

  // ── Helpers visuais ───────────────────────────────────────────────────────

  Widget _buildHeader(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                color: AppColors.secondary, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitulo,
            style: const TextStyle(color: AppColors.greyText, fontSize: 13)),
      ],
    );
  }

  Widget _buildBotoes({
    VoidCallback? onVoltar,
    required String labelVoltar,
    VoidCallback? onAvancar,
    required String labelAvancar,
    Color corAvancar = AppColors.secondary,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onVoltar,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text(labelVoltar,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onAvancar,
            style: ElevatedButton.styleFrom(
              backgroundColor: corAvancar,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(labelAvancar,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmar({required bool permanente}) async {
    setState(() => _loading = true);
    await widget.onConfirm(_quantidade, permanente: permanente);
    if (mounted) Navigator.of(context).pop();
  }

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
