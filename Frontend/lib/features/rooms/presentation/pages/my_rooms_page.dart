import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/room_category_card.dart';
import '../notifiers/my_rooms_notifier.dart';
import '../notifiers/my_rooms_state.dart';
import '../widgets/delete_room_dialog.dart';
import '../widgets/manual_reservation_dialog.dart';

class MyRoomsPage extends ConsumerStatefulWidget {
  const MyRoomsPage({super.key});

  @override
  ConsumerState<MyRoomsPage> createState() => _MyRoomsPageState();
}

class _MyRoomsPageState extends ConsumerState<MyRoomsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myRoomsNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRoomsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(state),
              _buildFiltroChips(state),
              Expanded(child: _buildBody(state)),
            ],
          ),
          _buildAddButton(state),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(MyRoomsState state) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  label: 'Voltar',
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/profile/host'),
                  ),
                ),
              ),
              const Column(
                children: [
                  Text('RESERVAQUI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Meus Quartos',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  label: 'Notificações',
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: () => context.go('/notifications'),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Semantics(
              label: 'Pesquisar quartos por nome',
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(myRoomsNotifierProvider.notifier).setBusca(v),
                decoration: InputDecoration(
                  hintText: 'Pesquisar por tipo de quarto...',
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  suffixIcon: const Icon(Icons.search,
                      color: AppColors.secondary),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtro Disponível / Indisponível ──────────────────────────────────────

  Widget _buildFiltroChips(MyRoomsState state) {
    final filtro = state.filtroDisponibilidade;
    final notifier = ref.read(myRoomsNotifierProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Center(child: _chip('Todos', filtro == FiltroDisponibilidade.todos,
              () => notifier.setFiltro(FiltroDisponibilidade.todos))),
          const SizedBox(width: 8),
          Center(child: _chip('Disponíveis',
              filtro == FiltroDisponibilidade.disponiveis,
              () => notifier.setFiltro(FiltroDisponibilidade.disponiveis))),
          const SizedBox(width: 8),
          Center(child: _chip('Indisponíveis',
              filtro == FiltroDisponibilidade.indisponiveis,
              () => notifier.setFiltro(FiltroDisponibilidade.indisponiveis))),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      label: '$label${selected ? ', selecionado' : ''}',
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.secondary,
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.only(left: 2, right: 6),
        labelStyle: TextStyle(
          color: selected ? AppColors.secondary : AppColors.greyText,
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(MyRoomsState state) {
    if (state.loading) return _buildLoading();
    if (state.error != null) return _buildError(state.error!);

    final cards = state.cardsFiltrados;
    if (cards.isEmpty && state.cards.isEmpty) return _buildEmpty();
    if (cards.isEmpty) return _buildEmptyFilter();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(myRoomsNotifierProvider.notifier).refresh(),
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.only(
            top: 16, bottom: 100, left: 16, right: 16),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return card.disponivel
              ? _buildCardAtivo(state, card)
              : _buildCardInativo(state, card);
        },
      ),
    );
  }

  Widget _buildLoading() => const Center(
      child: CircularProgressIndicator(color: AppColors.secondary));

  Widget _buildError(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.greyText, size: 48),
            const SizedBox(height: 16),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.greyText, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(myRoomsNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hotel_outlined,
                color: AppColors.greyText, size: 64),
            const SizedBox(height: 16),
            const Text('Nenhum quarto cadastrado',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Adicione o primeiro tipo de quarto do seu hotel.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.greyText, fontSize: 14)),
            const SizedBox(height: 24),
            Semantics(
              label: 'Adicionar primeiro quarto',
              child: ElevatedButton.icon(
                onPressed: () => context.push('/add_room'),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar quarto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                color: AppColors.greyText, size: 48),
            const SizedBox(height: 16),
            const Text('Nenhum resultado',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Tente outro nome ou ajuste o filtro.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.greyText, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Card Ativo ────────────────────────────────────────────────────────────

  Widget _buildCardAtivo(MyRoomsState state, RoomCategoryCardModel card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(11)),
                  child: card.fotoUrl != null
                      ? Image.network(card.fotoUrl!,
                          width: 110,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFotoPlaceholder())
                      : _buildFotoPlaceholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(card.nomeCategoria,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Semantics(
                              label: 'Editar ${card.nomeCategoria}',
                              child: GestureDetector(
                                onTap: () => context.push(
                                    '/edit_room/${card.quartoIds.first}'),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE8DB),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.secondary),
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: AppColors.secondary,
                                      size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _infoRow(Icons.meeting_room_outlined,
                            '${card.totalUnidades} unidade${card.totalUnidades != 1 ? 's' : ''}'),
                        if (card.valorBase != null) ...[
                          const SizedBox(height: 4),
                          _infoRow(Icons.attach_money,
                              'R\$ ${card.valorBase!.toStringAsFixed(2)}/dia'),
                        ],
                        if (card.descricao != null) ...[
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(card.descricao!,
                                style: const TextStyle(
                                    color: AppColors.greyText,
                                    fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBarraAcoes([
            _buildAcaoBtn(
                icon: Icons.calendar_month_outlined,
                label: 'Reserva manual',
                onTap: () => _abrirReservaManual(state, card)),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0x1F182541)),
            _buildAcaoBtn(
                icon: Icons.block,
                label: 'Desativar',
                cor: Colors.orange[700]!,
                onTap: () => _abrirDesativar(state, card)),
          ]),
        ],
      ),
    );
  }

  // ── Card Inativo ──────────────────────────────────────────────────────────

  Widget _buildCardInativo(MyRoomsState state, RoomCategoryCardModel card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: Row(
              children: [
                // Foto com overlay de inativo
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11)),
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 0.45,
                        child: card.fotoUrl != null
                            ? Image.network(card.fotoUrl!,
                                width: 110,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildFotoPlaceholder(inativo: true))
                            : _buildFotoPlaceholder(inativo: true),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Desativado',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.nomeCategoria,
                            style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        _infoRow(
                            Icons.meeting_room_outlined,
                            '${card.totalUnidades} unidade${card.totalUnidades != 1 ? 's' : ''}',
                            cor: AppColors.greyText),
                        const SizedBox(height: 4),
                        // Info de reserva ativa
                        card.proximaReservaAtiva != null
                            ? _infoRow(Icons.event_busy,
                                'Próxima reserva: ${_fmtData(card.proximaReservaAtiva!)}',
                                cor: Colors.orange[700]!)
                            : _infoRow(Icons.check_circle_outline,
                                'Sem reservas ativas',
                                cor: Colors.green[600]!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBarraAcoes([
            _buildAcaoBtn(
                icon: Icons.play_circle_outline,
                label: 'Reativar',
                cor: Colors.green[700]!,
                onTap: () => _abrirReativar(card)),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0x1F182541)),
            _buildAcaoBtn(
                icon: Icons.delete_outline,
                label: 'Remover',
                cor: Colors.red[600]!,
                onTap: () => _abrirRemoverInativo(card)),
          ]),
        ],
      ),
    );
  }

  // ── Shared card widgets ───────────────────────────────────────────────────

  Widget _buildBarraAcoes(List<Widget> children) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1F182541))),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(11),
            bottomRight: Radius.circular(11)),
      ),
      child: IntrinsicHeight(child: Row(children: children)),
    );
  }

  Widget _buildAcaoBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color cor = AppColors.primary,
  }) {
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(11),
              bottomRight: Radius.circular(11)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: cor),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text,
      {Color cor = AppColors.greyText}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: cor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: TextStyle(color: cor, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildFotoPlaceholder({bool inativo = false}) {
    return Container(
      width: 110,
      color: inativo
          ? const Color(0xFFDDDDDD)
          : AppColors.bgSecondary,
      child: Icon(Icons.hotel,
          color: inativo
              ? Colors.grey[400]
              : AppColors.greyText,
          size: 36),
    );
  }

  Widget _buildAddButton(MyRoomsState state) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          height: 40,
          width: 185,
          child: Semantics(
            label: 'Adicionar novo tipo de quarto',
            child: ElevatedButton(
              onPressed:
                  state.loading ? null : () => context.push('/add_room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF19D75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side:
                      const BorderSide(color: AppColors.secondary),
                ),
                elevation: 2,
              ),
              child: const Text('Adicionar',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _abrirDesativar(MyRoomsState state, RoomCategoryCardModel card) {
    final notifier = ref.read(myRoomsNotifierProvider.notifier);
    final temReserva = notifier.temReservaAtiva(card.quartoIds);
    final proxima   = notifier.proximaReservaAtiva(card.quartoIds);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteRoomDialog(
        nomeCategoria: card.nomeCategoria,
        totalUnidades: card.totalUnidades,
        temReservaAtiva: temReserva,
        proximaReservaAtiva: proxima,
        onConfirm: (quantidade, {required bool permanente}) async {
          final resultado = await notifier.deativarUnidades(
              card.categoriaId, quantidade,
              permanente: permanente);

          if (!mounted) return;
          _mostrarSnackbarAcao(
            resultado,
            permanente ? 'removida' : 'desativada',
          );
        },
      ),
    );
  }

  void _abrirReativar(RoomCategoryCardModel card) {
    showDialog<bool?>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline,
                  color: Colors.green, size: 44),
              const SizedBox(height: 12),
              const Text('Reativar unidades',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(card.nomeCategoria,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                'As ${card.totalUnidades} unidade${card.totalUnidades != 1 ? 's' : ''} voltarão a aceitar reservas.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.greyText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text('Reativar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmado) async {
      if (confirmado != true || !mounted) return;
      final resultado = await ref
          .read(myRoomsNotifierProvider.notifier)
          .reativarUnidades(card.categoriaId);
      if (!mounted) return;
      _mostrarSnackbarAcao(resultado, 'reativada');
    });
  }

  void _abrirRemoverInativo(RoomCategoryCardModel card) {
    final notifier = ref.read(myRoomsNotifierProvider.notifier);
    final bloqueio = notifier.verificarBloqueioExclusao(card.categoriaId);

    if (bloqueio != null) {
      // Exclusão bloqueada — mostra aviso sem opção de confirmar
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, color: Colors.orange[700], size: 44),
                const SizedBox(height: 12),
                Text('Exclusão bloqueada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(bloqueio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 14,
                        height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: const Text('Entendido',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Exclusão permitida — confirmar
    showDialog<bool?>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever, color: Colors.red[600], size: 44),
              const SizedBox(height: 12),
              const Text('Remover definitivamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(card.nomeCategoria,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 13)),
              const SizedBox(height: 12),
              const Text(
                'Esta ação excluirá as unidades permanentemente e não pode ser desfeita.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.greyText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text('Remover',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmado) async {
      if (confirmado != true || !mounted) return;
      final resultado = await ref
          .read(myRoomsNotifierProvider.notifier)
          .excluirUnidadesInativas(card.categoriaId);
      if (!mounted) return;
      _mostrarSnackbarAcao(resultado, 'removida');
    });
  }

  void _abrirReservaManual(MyRoomsState state, RoomCategoryCardModel card) {
    final diasIndisponiveis =
        state.diasIndisponiveisPorCategoria[card.categoriaId] ?? {};

    showDialog<bool?>(
      context: context,
      builder: (_) => ManualReservationDialog(
        nomeCategoria: card.nomeCategoria,
        valorBase: card.valorBase,
        diasIndisponiveis: diasIndisponiveis,
        onConfirm: ({
          required DateTime checkin,
          required DateTime checkout,
          required double valorTotal,
        }) async {
          return ref
              .read(myRoomsNotifierProvider.notifier)
              .criarReservaManual(
                categoriaId: card.categoriaId,
                checkin: checkin,
                checkout: checkout,
                valorTotal: valorTotal,
              );
        },
      ),
    ).then((sucesso) {
      if (!mounted || sucesso != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva manual criada com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _mostrarSnackbarAcao(Map<String, int> resultado, String verbo) {
    final sucesso = resultado['sucesso'] ?? 0;
    final falha   = resultado['falha'] ?? 0;
    final msg = falha == 0
        ? '$sucesso unidade${sucesso != 1 ? 's' : ''} ${verbo}s com sucesso.'
        : '$sucesso/${sucesso + falha} unidade${sucesso != 1 ? 's' : ''} ${verbo}s. $falha não puderam ser processadas.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: falha == 0 ? Colors.green[700] : Colors.orange[700],
    ));
  }

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
