import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/tickets_service.dart';
import '../../domain/models/ticket.dart';
import '../notifiers/tickets_notifier.dart';
import '../widgets/approval_bottom_sheet.dart';

// ── Modelos locais para detalhe ───────────────────────────────────────────────

class _ReservaInfo {
  final String codigoPublico;
  final String? nomeHospede;
  final String tipoQuarto;
  final DateTime checkIn;
  final DateTime checkOut;
  final String? horaCheckinReal;
  final String? horaCheckoutReal;
  final int numHospedes;
  final double valorTotal;
  final String status;
  final String? observacoes;

  const _ReservaInfo({
    required this.codigoPublico,
    this.nomeHospede,
    required this.tipoQuarto,
    required this.checkIn,
    required this.checkOut,
    this.horaCheckinReal,
    this.horaCheckoutReal,
    required this.numHospedes,
    required this.valorTotal,
    required this.status,
    this.observacoes,
  });

  factory _ReservaInfo.fromJson(Map<String, dynamic> j) {
    return _ReservaInfo(
      codigoPublico: j['codigo_publico']?.toString() ?? '',
      nomeHospede: j['nome_hospede']?.toString(),
      tipoQuarto: j['tipo_quarto']?.toString() ?? '—',
      checkIn: DateTime.tryParse(j['data_checkin']?.toString() ?? '') ?? DateTime.now(),
      checkOut: DateTime.tryParse(j['data_checkout']?.toString() ?? '') ?? DateTime.now(),
      horaCheckinReal: j['hora_checkin_real']?.toString(),
      horaCheckoutReal: j['hora_checkout_real']?.toString(),
      numHospedes: j['num_hospedes'] is int
          ? j['num_hospedes'] as int
          : int.tryParse(j['num_hospedes']?.toString() ?? '') ?? 1,
      valorTotal: _parseDouble(j['valor_total']),
      status: j['status']?.toString() ?? '',
      observacoes: j['observacoes']?.toString(),
    );
  }

  TicketStatus get ticketStatus {
    if (status == 'SOLICITADA' || status == 'AGUARDANDO_PAGAMENTO') return TicketStatus.aguardo;
    if (status == 'APROVADA') {
      return horaCheckinReal != null ? TicketStatus.hospedado : TicketStatus.aprovado;
    }
    if (status == 'CONCLUIDA') return TicketStatus.finalizado;
    if (status == 'CANCELADA') return TicketStatus.cancelado;
    return TicketStatus.aguardo;
  }

  bool get podeCancelar =>
      status == 'SOLICITADA' || status == 'AGUARDANDO_PAGAMENTO';

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class _ItemInfo {
  final String nome;
  final int quantidade;
  const _ItemInfo({required this.nome, required this.quantidade});
}

class _CategoriaInfo {
  final String nome;
  final int capacidadePessoas;
  final List<_ItemInfo> itens;
  const _CategoriaInfo({required this.nome, required this.capacidadePessoas, required this.itens});

  factory _CategoriaInfo.fromJson(Map<String, dynamic> j) {
    final rawItens = (j['itens'] as List? ?? []).cast<Map<String, dynamic>>();
    return _CategoriaInfo(
      nome: j['nome']?.toString() ?? '',
      capacidadePessoas: j['capacidade_pessoas'] is int
          ? j['capacidade_pessoas'] as int
          : int.tryParse(j['capacidade_pessoas']?.toString() ?? '') ?? 0,
      itens: rawItens
          .map((i) => _ItemInfo(
                nome: i['nome']?.toString() ?? '',
                quantidade: i['quantidade'] is int
                    ? i['quantidade'] as int
                    : int.tryParse(i['quantidade']?.toString() ?? '') ?? 1,
              ))
          .toList(),
    );
  }
}

class _ConfiguracaoInfo {
  final String horarioCheckin;
  final String horarioCheckout;
  final String? politicaCancelamento;
  final bool aceitaAnimais;
  const _ConfiguracaoInfo({
    required this.horarioCheckin,
    required this.horarioCheckout,
    this.politicaCancelamento,
    required this.aceitaAnimais,
  });

  factory _ConfiguracaoInfo.fromJson(Map<String, dynamic> j) {
    return _ConfiguracaoInfo(
      horarioCheckin: j['horario_checkin']?.toString() ?? '—',
      horarioCheckout: j['horario_checkout']?.toString() ?? '—',
      politicaCancelamento: j['politica_cancelamento']?.toString(),
      aceitaAnimais: j['aceita_animais'] == true,
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class TicketDetailsPage extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends ConsumerState<TicketDetailsPage> {
  _ReservaInfo? _reserva;
  _CategoriaInfo? _categoria;
  _ConfiguracaoInfo? _configuracao;
  bool _loading = true;
  String? _error;
  bool _canceling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    final service = ref.read(ticketsServiceProvider);

    final hotelId = ref.read(ticketsNotifierProvider).asData?.value
        .cast<Ticket?>()
        .firstWhere((t) => t?.id == widget.ticketId, orElse: () => null)
        ?.hotelId;

    try {
      final reservaJson = await service.fetchReservaByCodigoPublico(widget.ticketId);
      final reserva = _ReservaInfo.fromJson(reservaJson);

      _CategoriaInfo? categoria;
      _ConfiguracaoInfo? configuracao;

      if (hotelId != null && hotelId.isNotEmpty) {
        final results = await Future.wait([
          service
              .fetchCategoriaByNome(hotelId, reserva.tipoQuarto)
              .catchError((_) => null as Map<String, dynamic>?),
          service
              .fetchConfiguracaoHotel(hotelId)
              .catchError((_) => null as Map<String, dynamic>?),
        ]);

        final catJson = results[0];
        final configJson = results[1];

        if (catJson != null) categoria = _CategoriaInfo.fromJson(catJson);
        if (configJson != null) configuracao = _ConfiguracaoInfo.fromJson(configJson);
      }

      if (mounted) {
        setState(() {
          _reserva = reserva;
          _categoria = categoria;
          _configuracao = configuracao;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os dados da reserva.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmarCancelamento() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('Tem certeza que deseja cancelar esta reserva? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF2828)),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _canceling = true);

    try {
      await ref.read(ticketsNotifierProvider.notifier).cancelarReserva(widget.ticketId);
      if (mounted) {
        setState(() {
          _reserva = _ReservaInfo(
            codigoPublico: _reserva!.codigoPublico,
            nomeHospede: _reserva!.nomeHospede,
            tipoQuarto: _reserva!.tipoQuarto,
            checkIn: _reserva!.checkIn,
            checkOut: _reserva!.checkOut,
            horaCheckinReal: _reserva!.horaCheckinReal,
            horaCheckoutReal: _reserva!.horaCheckoutReal,
            numHospedes: _reserva!.numHospedes,
            valorTotal: _reserva!.valorTotal,
            status: 'CANCELADA',
            observacoes: _reserva!.observacoes,
          );
          _canceling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _canceling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHigh,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final reserva = _reserva!;
    final theme = TicketStatusTheme.of(reserva.ticketStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        children: [
          _buildMainCard(reserva, theme),
          const SizedBox(height: 16),
          if (_categoria != null || _configuracao != null) ...[
            _buildDetailsCard(reserva),
            const SizedBox(height: 16),
          ],
          _buildFinancialCard(reserva),
          if (reserva.podeCancelar) ...[
            const SizedBox(height: 16),
            _buildCancelButton(),
          ],
        ],
      ),
    );
  }

  Widget _manageButton(Ticket ticket) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.rule, size: 18),
        label: const Text('Gerenciar reserva', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        onPressed: () => _openApprovalSheet(ticket),
      ),
    );
  }

  Future<void> _openApprovalSheet(Ticket ticket) async {
    final id = int.tryParse(ticket.id);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de reserva inválido.')),
      );
      return;
    }

    final notifier = ref.read(ticketsNotifierProvider.notifier);

    final statusLabel = ticket.statusRaw == 'AGUARDANDO_PAGAMENTO'
        ? 'Pagamento confirmado — aguardando sua aprovação'
        : 'Aguardando sua aprovação';

    final datas =
        '${_fmt(ticket.checkIn)} → ${_fmt(ticket.checkOut)}';

    final result = await showApprovalBottomSheet(
      context: context,
      resumo: ApprovalResumo(
        nomeHospede:  ticket.hotelName, // reutiliza hotelName como nome do hóspede quando host vê (backend retorna nome_hotel)
        datas:        datas,
        tipoQuarto:   ticket.roomType,
        valorTotal:   ticket.total,
        statusAtual:  statusLabel,
      ),
      onApprove: () async {
        final err = await notifier.aprovarReserva(id);
        return err == null
            ? const ApprovalOutcome.success()
            : ApprovalOutcome.failure(err);
      },
      onReject: () async {
        final err = await notifier.negarReserva(id);
        return err == null
            ? const ApprovalOutcome.success()
            : ApprovalOutcome.failure(err);
      },
    );

    if (!mounted || result == null) return;

    final isApprove = result == ApprovalResult.approved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApprove ? 'Reserva aprovada.' : 'Reserva cancelada.'),
        backgroundColor: isApprove ? const Color(0xFF1E7A1E) : const Color(0xFFC0392B),
      ),
    );
    if (context.canPop()) context.pop();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

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
                  _headerButton(icon: Icons.chevron_left, onTap: () => context.pop(), context: context),
                  SvgPicture.asset('lib/assets/icons/logo/logoDark.svg', height: 28),
                  _headerButton(icon: Icons.notifications_none, onTap: () => context.go('/notifications'), context: context),
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

  Widget _headerButton({required IconData icon, required VoidCallback onTap, required BuildContext context}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.79,
        height: 45.79,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.37),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.17), width: 0.62),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Card principal ────────────────────────────────────────────────────────

  Widget _buildMainCard(_ReservaInfo reserva, TicketStatusTheme theme) {
    final colorScheme = Theme.of(context).colorScheme;
    final checkinDisplay = reserva.horaCheckinReal ?? _configuracao?.horarioCheckin ?? '—';
    final checkoutDisplay = reserva.horaCheckoutReal ?? _configuracao?.horarioCheckout ?? '—';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reserva.tipoQuarto,
                  style: TextStyle(
                    color: colorScheme.onSurface, fontSize: 12,
                    fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w700, height: 1.67,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check-in: ${_fullDate(reserva.checkIn)}',
                  style: TextStyle(
                    color: colorScheme.onSurface, fontSize: 12,
                    fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w400, height: 1.67,
                  ),
                ),
                Text(
                  'Check-out: ${_fullDate(reserva.checkOut)}',
                  style: TextStyle(
                    color: colorScheme.onSurface, fontSize: 12,
                    fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w400, height: 1.67,
                  ),
                ),
              ],
            ),
          ),
          _infoRow('Chegada', checkinDisplay, 'Saída', checkoutDisplay),
          _infoRow('Ticket ID', reserva.codigoPublico.length > 8
              ? reserva.codigoPublico.substring(0, 8).toUpperCase()
              : reserva.codigoPublico,
              'Status', theme.label, rightValueColor: theme.badgeColor),
          if (reserva.nomeHospede != null && reserva.nomeHospede!.isNotEmpty)
            _infoRow('Hóspede', reserva.nomeHospede!, 'Quarto', reserva.tipoQuarto),
          _infoRow('Hóspedes', '${reserva.numHospedes} adulto${reserva.numHospedes != 1 ? 's' : ''}',
              'Total', 'R\$${reserva.valorTotal.toStringAsFixed(2)}',
              isLast: reserva.observacoes == null),
          if (reserva.observacoes != null)
            _observacoesRow(reserva.observacoes!),
        ],
      ),
    );
  }

  // ── Card de detalhes ──────────────────────────────────────────────────────

  Widget _buildDetailsCard(_ReservaInfo reserva) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_categoria != null) ...[
            _detailsTitle('Sobre o quarto'),
            const SizedBox(height: 8),
            _infoLine(Icons.people_outline,
                'Capacidade: até ${_categoria!.capacidadePessoas} pessoa${_categoria!.capacidadePessoas != 1 ? 's' : ''}'),
            const SizedBox(height: 6),
            ..._categoria!.itens.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _infoLine(Icons.check_circle_outline,
                    '${item.nome} (${item.quantidade}x)'),
              ),
            ),
          ],
          if (_categoria != null && _configuracao != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: colorScheme.outline, thickness: 0.5),
            ),
          if (_configuracao != null) ...[
            _detailsTitle('Política do hotel'),
            const SizedBox(height: 8),
            _infoLine(Icons.login, 'Check-in: ${_configuracao!.horarioCheckin}'),
            const SizedBox(height: 4),
            _infoLine(Icons.logout, 'Check-out: ${_configuracao!.horarioCheckout}'),
            const SizedBox(height: 4),
            _infoLine(
              _configuracao!.aceitaAnimais ? Icons.pets : Icons.do_not_disturb,
              _configuracao!.aceitaAnimais ? 'Aceita animais de estimação' : 'Não aceita animais de estimação',
            ),
            if (_configuracao!.politicaCancelamento != null &&
                _configuracao!.politicaCancelamento!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Cancelamento:',
                style: TextStyle(
                  color: colorScheme.onSurface, fontSize: 12,
                  fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w700, height: 1.67,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _configuracao!.politicaCancelamento!,
                style: TextStyle(
                  color: colorScheme.onSurface, fontSize: 12,
                  fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w400, height: 1.67,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Card financeiro ───────────────────────────────────────────────────────

  Widget _buildFinancialCard(_ReservaInfo reserva) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _financialRow('Subtotal', 'R\$${reserva.valorTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _financialRow('Descontos', '-R\$0,00'),
          const SizedBox(height: 10),
          _financialRow('Taxas', 'R\$0,00'),
          const SizedBox(height: 10),
          _financialRow('Total', 'R\$${reserva.valorTotal.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  // ── Botão cancelar ────────────────────────────────────────────────────────

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _canceling ? null : _confirmarCancelamento,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF2828),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _canceling
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Cancelar reserva',
                style: TextStyle(
                  fontSize: 14, fontFamily: 'Stack Sans Headline', fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ── Helpers de layout ─────────────────────────────────────────────────────

  Widget _infoRow(
    String leftLabel, String leftValue,
    String rightLabel, String rightValue, {
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
              Text(leftLabel, style: _labelStyle),
              Text(leftValue, style: _valueStyle),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: _labelStyle),
              Text(rightValue, style: _valueStyle.copyWith(color: rightValueColor ?? colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _observacoesRow(String obs) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 0.5, color: colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Observações', style: _labelStyle),
          const SizedBox(height: 2),
          Text(obs, style: _valueStyle),
        ],
      ),
    );
  }

  Widget _detailsTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface, fontSize: 12,
        fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w700, height: 1.67,
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    
    return Row(
      children: [
        Icon(icon, size: 14, color: onSurfaceColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: _valueStyle),
        ),
      ],
    );
  }

  Widget _financialRow(String label, String value, {bool isTotal = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isTotal ? AppColors.secondary : colorScheme.onSurface;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w700, height: 1.40)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Stack Sans Text', fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400, height: 1.40)),
      ],
    );
  }

  String _fullDate(DateTime d) {
    const weekdays = [
      'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado', 'domingo',
    ];
    final day = weekdays[d.weekday - 1];
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, $day';
  }

  TextStyle get _labelStyle => TextStyle(
    color: Theme.of(context).colorScheme.onSurface, fontSize: 12,
    fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w700, height: 1.67,
  );

  TextStyle get _valueStyle => TextStyle(
    color: Theme.of(context).colorScheme.onSurface, fontSize: 12,
    fontFamily: 'Stack Sans Text', fontWeight: FontWeight.w300, height: 1.67,
  );
}
