import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/booking_service.dart';

/// Visualização pública (sem login) do ticket de uma reserva.
/// Acessível via deep-link `/reservas/:codigoPublico` — usado pelos guests
/// que recebem o link por email.
class PublicTicketPage extends ConsumerStatefulWidget {
  final String codigoPublico;

  const PublicTicketPage({super.key, required this.codigoPublico});

  @override
  ConsumerState<PublicTicketPage> createState() => _PublicTicketPageState();
}

class _PublicTicketPageState extends ConsumerState<PublicTicketPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    await ref.read(bookingServiceProvider).fetchReservaPublica(
      codigoPublico: widget.codigoPublico,
      onSuccess: (d) => setState(() { _data = d; _loading = false; }),
      onError:   (e) => setState(() { _error = e; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Minha reserva'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildTicket(_data!),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error ?? 'Reserva não encontrada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildTicket(Map<String, dynamic> d) {
    final codigoPublico = (d['codigo_publico'] ?? widget.codigoPublico).toString();
    final status        = (d['status'] ?? '').toString();
    final tipoQuarto    = (d['tipo_quarto'] ?? 'Quarto').toString();
    final numHospedes   = d['num_hospedes'] ?? 1;
    final dataCheckin   = (d['data_checkin']  ?? '').toString();
    final dataCheckout  = (d['data_checkout'] ?? '').toString();
    final valorTotal    = double.tryParse(d['valor_total']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusCard(status),
          const SizedBox(height: 14),
          _card([
            _row('Código', codigoPublico, selectable: true),
            _divider(),
            _row('Quarto', tipoQuarto),
            _divider(),
            _row('Hóspedes', '$numHospedes'),
          ]),
          const SizedBox(height: 14),
          _card([
            _row('Check-in',  _fmtDate(dataCheckin)),
            _divider(),
            _row('Check-out', _fmtDate(dataCheckout)),
          ]),
          const SizedBox(height: 14),
          _card([
            _row('Total', 'R\$ ${valorTotal.toStringAsFixed(2)}', highlight: true),
          ]),
          const SizedBox(height: 14),
          Text(
            'Guarde este código — ele é sua referência junto ao hotel.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'APROVADA':
        bg = const Color(0xFF1E7A1E).withValues(alpha: 0.12);
        fg = const Color(0xFF1E7A1E);
        label = 'Confirmada';
        break;
      case 'SOLICITADA':
      case 'AGUARDANDO_PAGAMENTO':
        bg = AppColors.secondary.withValues(alpha: 0.15);
        fg = AppColors.secondary;
        label = status == 'AGUARDANDO_PAGAMENTO' ? 'Aguardando pagamento' : 'Solicitada';
        break;
      case 'CANCELADA':
        bg = const Color(0xFFFDE8E8);
        fg = const Color(0xFFC0392B);
        label = 'Cancelada';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: fg),
          const SizedBox(width: 10),
          Text('Status: $label',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, {bool highlight = false, bool selectable = false}) {
    final valueStyle = TextStyle(
      color: highlight ? AppColors.secondary : AppColors.primary,
      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
      fontSize: highlight ? 16 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          Flexible(
            child: selectable
                ? SelectableText(value, style: valueStyle, textAlign: TextAlign.right)
                : Text(value, style: valueStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFE6E6E6));

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
