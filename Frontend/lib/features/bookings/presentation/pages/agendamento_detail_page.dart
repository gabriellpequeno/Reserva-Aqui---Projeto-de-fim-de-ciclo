import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tickets/data/services/tickets_service.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../notifiers/agendamentos_notifier.dart';

class AgendamentoDetailPage extends ConsumerStatefulWidget {
  const AgendamentoDetailPage({super.key, required this.reservaId});

  final int reservaId;

  @override
  ConsumerState<AgendamentoDetailPage> createState() => _AgendamentoDetailPageState();
}

class _AgendamentoDetailPageState extends ConsumerState<AgendamentoDetailPage> {
  Map<String, dynamic>? _reserva;
  String? _error;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(ticketsServiceProvider).fetchReservaById(widget.reservaId);
      if (mounted) setState(() { _reserva = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _aprovar() async {
    setState(() => _actionLoading = true);
    final err = await ref.read(agendamentosNotifierProvider.notifier).aprovarReserva(widget.reservaId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err != null) {
      _showSnackBar(err, isError: true);
    } else {
      _showSnackBar('Reserva aprovada com sucesso!');
      await _load();
    }
  }

  Future<void> _cancelar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('Tem certeza que deseja cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    final err = await ref.read(agendamentosNotifierProvider.notifier).negarReserva(widget.reservaId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err != null) {
      _showSnackBar(err, isError: true);
    } else {
      _showSnackBar('Reserva cancelada.');
      await _load();
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/host/agendamentos'),
                child: Container(
                  width: 45.79,
                  height: 45.79,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.37),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.17), width: 0.62),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                ),
              ),
              const Text(
                'Detalhe do Agendamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 45.79),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: const Text('Tentar Novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _reserva!;
    final statusRaw = r['status']?.toString() ?? '';
    final ticket = Ticket.fromJson(r);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(ticket),
          const SizedBox(height: 20),
          _buildInfoSection(r, ticket),
          const SizedBox(height: 28),
          if (!_actionLoading) _buildActions(statusRaw) else const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Ticket ticket) {
    final theme = TicketStatusTheme.of(ticket.status);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.badgeColor),
        ),
        child: Text(
          theme.label,
          style: TextStyle(
            color: theme.badgeColor,
            fontFamily: 'Stack Sans Headline',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> r, Ticket ticket) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _infoRow('Código', r['codigo_publico']?.toString() ?? '—'),
            _infoRow('Hóspede', r['nome_hospede']?.toString() ?? r['user_id']?.toString() ?? '—'),
            _infoRow('Quarto / Categoria', r['tipo_quarto']?.toString() ?? '—'),
            _infoRow('Check-in', ticket.formattedCheckIn),
            _infoRow('Check-out', ticket.formattedCheckOut),
            _infoRow('Hóspedes', '${ticket.guestCount}'),
            _infoRow(
              'Total',
              'R\$ ${ticket.total.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Stack Sans Text',
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Stack Sans Text',
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(String statusRaw) {
    // CONCLUIDA / CANCELADA → somente leitura
    if (statusRaw == 'CONCLUIDA' || statusRaw == 'CANCELADA') {
      return const SizedBox.shrink();
    }

    // Aguardando aprovação do host (qualquer variante pré-aprovação)
    final aguardandoAprovacao = statusRaw == 'SOLICITADA' || statusRaw == 'AGUARDANDO_PAGAMENTO';

    return Column(
      children: [
        // Aguardando aprovação → Confirmar + Cancelar
        if (aguardandoAprovacao) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _aprovar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
        // APROVADA / HOSPEDADO → apenas Cancelar
        if (statusRaw == 'APROVADA') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelar,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar reserva'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[700]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
