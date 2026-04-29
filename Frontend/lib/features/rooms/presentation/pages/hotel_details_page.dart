import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/hotel_details.dart';
import '../notifiers/hotel_details_notifier.dart';
import '../notifiers/hotel_details_state.dart';

class HotelDetailsPage extends ConsumerStatefulWidget {
  final String hotelId;

  const HotelDetailsPage({
    super.key,
    required this.hotelId,
  });

  @override
  ConsumerState<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends ConsumerState<HotelDetailsPage> {
  late Set<int> _selectedCapacidades;

  @override
  void initState() {
    super.initState();
    _selectedCapacidades = {};
    // Gatilho de carregamento ao montar a tela
    Future.microtask(() {
      ref.read(hotelDetailsNotifierProvider.notifier).loadHotel(widget.hotelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelDetailsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar detalhes do hotel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(hotelDetailsNotifierProvider.notifier)
                            .loadHotel(widget.hotelId),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(context, state),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar abaixo da foto de capa com 15px de espaço
                              const SizedBox(height: 15),
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    color: Colors.grey[200],
                                    image: state.coverUrls.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(state.coverUrls[0]),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            image: AssetImage('lib/assets/images/home_page.jpeg'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(state),
                                    const Divider(height: 48, color: Color(0xFFE0E0E0)),
                                    Center(child: _buildSectionTitle('Descrição')),
                                    const SizedBox(height: 12),
                                    Text(
                                      state.descricao ?? 'Sem descrição disponível',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (state.politicas != null) ...[
                                      const SizedBox(height: 12),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () => _showPoliticasModal(context, state.politicas!),
                                          child: const Text(
                                            'Ver políticas do hotel',
                                            style: TextStyle(
                                              color: AppColors.secondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.underline,
                                              decorationColor: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (state.comodidades.isNotEmpty) ...[
                                      const Divider(height: 48, color: Color(0xFFE0E0E0)),
                                      _buildSectionTitle('Comodidades'),
                                      const SizedBox(height: 16),
                                      _buildComodidades(state.comodidades),
                                    ],
                                    const Divider(height: 48, color: Color(0xFFE0E0E0)),
                                    _buildRichSectionTitle('Quartos ', 'Disponíveis'),
                                    const SizedBox(height: 16),
                                    _buildBedFilter(state.categorias),
                                    const SizedBox(height: 16),
                                    _buildCategorias(state.categorias, _selectedCapacidades),
                                    const Divider(height: 48, color: Color(0xFFE0E0E0)),
                                    _buildSectionTitle('Avaliações'),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        state.notaMedia.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < state.notaMedia.toInt()
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: AppColors.secondary,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (state.avaliacoes.isNotEmpty)
                                      _buildAvaliacoes(state.avaliacoes)
                                    else
                                      const Center(
                                        child: Text(
                                          'Nenhuma avaliação ainda',
                                          style: TextStyle(color: AppColors.greyText),
                                        ),
                                      ),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showPoliticasModal(BuildContext context, PoliticasHotelModel politicas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Políticas do Hotel',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildPoliticaRow('Check-in', politicas.horarioCheckin),
              _buildPoliticaRow('Check-out', politicas.horarioCheckout),
              if (politicas.politicaCancelamento != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Cancelamento',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  politicas.politicaCancelamento!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HotelDetailsState state) {
    final imageUrl = state.coverUrls.isNotEmpty ? state.coverUrls[0] : null;

    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: false,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset('lib/assets/images/home_page.jpeg', fit: BoxFit.cover),
                  )
                : Image.asset('lib/assets/images/home_page.jpeg', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, size: 20),
              onPressed: () => context.go('/notifications'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(HotelDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          state.nome ?? 'Hotel',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: AppColors.greyText, size: 16),
            const SizedBox(width: 4),
            Text(
              '${state.cidade ?? ''}, ${state.uf ?? ''}',
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRichSectionTitle(String primary, String secondary) {
    return Text.rich(
      TextSpan(
        text: primary,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: secondary,
            style: const TextStyle(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliticaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Mapeia nomes de comodidades para ícones Material padronizados
  static IconData _iconForItem(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('wi-fi') || n.contains('wifi') || n.contains('internet')) return Icons.wifi;
    if (n.contains('ar-condicionado') || n.contains('ar condicionado') || n.contains('ac')) return Icons.ac_unit;
    if (n.contains('tv') || n.contains('televisão') || n.contains('cabo')) return Icons.tv;
    if (n.contains('frigobar') || n.contains('geladeira') || n.contains('minibar')) return Icons.kitchen;
    if (n.contains('cofre')) return Icons.lock;
    if (n.contains('piscina')) return Icons.pool;
    if (n.contains('academia') || n.contains('gym') || n.contains('ginásio')) return Icons.fitness_center;
    if (n.contains('spa')) return Icons.spa;
    if (n.contains('restaurante') || n.contains('café da manhã') || n.contains('refeição')) return Icons.restaurant;
    if (n.contains('estacionamento') || n.contains('garagem')) return Icons.local_parking;
    if (n.contains('banheiro') || n.contains('ducha') || n.contains('chuveiro')) return Icons.shower;
    if (n.contains('varanda') || n.contains('sacada') || n.contains('terraço')) return Icons.balcony;
    if (n.contains('king')) return Icons.king_bed;
    if (n.contains('queen') || n.contains('casal')) return Icons.bed;
    if (n.contains('solteiro') || n.contains('single')) return Icons.single_bed;
    return Icons.check_circle_outline;
  }

  Widget _buildComodidades(List<ComodidadeHotelModel> comodidades) {
    // Exibe apenas COMODIDADE e LAZER — COMODO (camas/banheiro) fica nos cards de quarto
    final itens = comodidades
        .where((c) => c.categoria != 'COMODO')
        .toList();

    if (itens.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: itens.map((com) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForItem(com.nome), size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                com.nome,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBedFilter(List<CategoriaHotelModel> categorias) {
    final capacidades = <int>{};
    for (final cat in categorias) {
      capacidades.add(cat.capacidadePessoas);
    }
    final capacidadesSorted = capacidades.toList()..sort();

    if (capacidadesSorted.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: capacidadesSorted.map((cap) {
        final isSelected = _selectedCapacidades.contains(cap);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCapacidades.remove(cap);
              } else {
                _selectedCapacidades.add(cap);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.king_bed_outlined,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$cap pessoa${cap > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorias(
    List<CategoriaHotelModel> categorias,
    Set<int> selectedCapacidades,
  ) {
    final categoriasFiltradas = selectedCapacidades.isEmpty
        ? categorias
        : categorias.where((c) => selectedCapacidades.contains(c.capacidadePessoas)).toList();

    if (categoriasFiltradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Nenhum quarto disponível para o filtro selecionado',
            style: TextStyle(color: AppColors.greyText),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: categoriasFiltradas.map((cat) {
        // Itens visíveis: apenas COMODIDADE e LAZER (COMODO são as camas, já no nome da categoria)
        final itensVisiveis = cat.itens.where((i) => i.categoria != 'COMODO').toList();
        final podeNavegar = cat.primeiroQuartoId != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: podeNavegar
                ? () => context.push(
                      '/room_details/${widget.hotelId}/${cat.primeiroQuartoId}',
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.nome,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capacidade: ${cat.capacidadePessoas} pessoa${cat.capacidadePessoas > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'R\$ ${cat.preco.toStringAsFixed(0)}/noite',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (podeNavegar) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.greyText,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (itensVisiveis.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: itensVisiveis.map((item) {
                        return Chip(
                          avatar: Icon(
                            _iconForItem(item.nome),
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            item.nome,
                            style: const TextStyle(fontSize: 11),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvaliacoes(List<AvaliacaoHotelModel> avaliacoes) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avaliacoes.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Divider(height: 1, color: Color(0xFFE0E0E0)),
      ),
      itemBuilder: (context, index) {
        final review = avaliacoes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFD9D9D9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.nomeUsuario,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.notaTotal.toInt()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.secondary,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  review.timeAgo,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (review.comentario != null && review.comentario!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Text(
                  review.comentario!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
