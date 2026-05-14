import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../domain/models/room.dart';
import '../notifiers/room_details_notifier.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../favorites/presentation/widgets/favorite_dialogs.dart';

class RoomDetailsPage extends ConsumerStatefulWidget {
  final String hotelId;
  final String roomId;

  const RoomDetailsPage({
    super.key,
    required this.hotelId,
    required this.roomId,
  });

  @override
  ConsumerState<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends ConsumerState<RoomDetailsPage> {
  late PageController _photoController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
    Future.microtask(() {
      ref
          .read(roomDetailsNotifierProvider.notifier)
          .loadRoom(widget.hotelId, widget.roomId);
    });
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  void _handleShareTap(Room room) {
    final link =
        'https://reservaqui.com/hotel/${widget.hotelId}/room/${widget.roomId}';
    Clipboard.setData(ClipboardData(text: link));
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Link copiado para a área de transferência',
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        backgroundColor: colorScheme.inverseSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomDetailsNotifierProvider);
    final isFavorite = ref.watch(favoritesProvider).value
            ?.any((h) => h.hotelId == widget.hotelId) ??
        false;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: roomState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar detalhes do quarto',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(roomDetailsNotifierProvider.notifier)
                            .loadRoom(widget.hotelId, widget.roomId),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? _buildDesktopLayout(context, roomState.room!, isFavorite)
                  : _buildMobileLayout(context, roomState.room!, isFavorite),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESKTOP — 2 colunas, sem back button, sem bottom bar fixo
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      BuildContext context, Room room, bool isFavorite) {
    final colorScheme = Theme.of(context).colorScheme;
    final galleryUrls = room.imageUrls.isNotEmpty
        ? room.imageUrls
        : fallbacksForRoom(room.title, widget.hotelId, 4);
    final safeIndex = _currentPhotoIndex.clamp(0, galleryUrls.length - 1);
    final mainImageUrl = galleryUrls[safeIndex];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galeria à esquerda
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: SmartNetworkImage(
                                url: mainImageUrl.isNotEmpty
                                    ? mainImageUrl
                                    : null,
                                fallback: fallbackForRoom(room.title,
                                    hotelId: widget.hotelId),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _buildCircularButton(
                              icon: isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              iconColor:
                                  isFavorite ? Colors.redAccent : Colors.white,
                              onTap: _toggleFavorite,
                            ),
                          ),
                        ],
                      ),
                      if (galleryUrls.length > 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: galleryUrls.length.clamp(0, 6),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final url = galleryUrls[index];
                              final isSelected = safeIndex == index;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _currentPhotoIndex = index),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.secondary
                                          : colorScheme.outline,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SmartNetworkImage(
                                      url: url.isNotEmpty ? url : null,
                                      fallback: fallbackForRoom(room.title,
                                          hotelId: widget.hotelId),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                // Info à direita
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context
                            .push('/hotel_details/${widget.hotelId}'),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text(
                            room.hotelName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.title,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'R\$ ${room.price.toInt()}',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ dia',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle('Comodidades'),
                      const SizedBox(height: 12),
                      _buildAmenitiesGrid(room.amenities),
                      const SizedBox(height: 28),
                      _sectionTitle('Detalhes'),
                      const SizedBox(height: 12),
                      Text(
                        room.description,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle('Anfitrião'),
                      const SizedBox(height: 12),
                      _buildHostSection(context, room.host),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _goToCheckout(room),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Reservar',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _handleShareTap(room),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              minimumSize: const Size(54, 54),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side:
                                  BorderSide(color: colorScheme.outline),
                            ),
                            child: Icon(Icons.share_outlined,
                                color: colorScheme.onSurface, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToCheckout(Room room) {
    final roomState = ref.read(roomDetailsNotifierProvider);
    context.push(
        '/booking/checkout/${widget.hotelId}/${roomState.categoriaId}/${room.id}');
  }

  Widget _sectionTitle(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MOBILE / TABLET — comportamento original
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      BuildContext context, Room room, bool isFavorite) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ResponsiveCenter(
          maxWidth: ContentMaxWidth.content,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(room, isFavorite: isFavorite),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context
                            .push('/hotel_details/${widget.hotelId}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.hotelName,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              room.title,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Comodidades',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAmenitiesGrid(room.amenities),
                      const SizedBox(height: 32),
                      Text(
                        'Detalhes',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        room.description,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildHostSection(context, room.host),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(context, room),
      ],
    );
  }

  Widget _buildImageSection(Room room, {required bool isFavorite}) {
    // When no real photos, fill gallery with 4 deterministic room mocks for this hotel
    final galleryUrls = room.imageUrls.isNotEmpty
        ? room.imageUrls
        : fallbacksForRoom(room.title, widget.hotelId, 4);
    final safeIndex = _currentPhotoIndex.clamp(0, galleryUrls.length - 1);
    final mainImageUrl = galleryUrls[safeIndex];

    // Card de preço: light = fundo azul-marinho com texto laranja;
    // dark = inverte para ganhar contraste contra o fundo escuro.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceCardBg = isDark ? AppColors.secondary : AppColors.primary;
    final priceCardFg = isDark ? AppColors.primary : AppColors.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: SizedBox(
            height: 400,
            width: double.infinity,
            child: SmartNetworkImage(
              url: mainImageUrl.isNotEmpty ? mainImageUrl : null,
              fallback: fallbackForRoom(room.title, hotelId: widget.hotelId),
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: _buildCircularButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
          ),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: _buildCircularButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavorite ? Colors.redAccent : Colors.white,
            onTap: _toggleFavorite,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: FractionalTranslation(
            translation: const Offset(0, 0.5),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                decoration: BoxDecoration(
                  color: priceCardBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            color: priceCardFg,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          '${room.price.toInt()}',
                          style: TextStyle(
                            color: priceCardFg,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'por dia',
                        style: TextStyle(
                          color: priceCardFg,
                          fontSize: 8,
                          fontWeight: FontWeight.w300,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (galleryUrls.length > 1)
          Positioned(
            bottom: 0,
            right: 24,
            child: FractionalTranslation(
              translation: const Offset(0, 0.5),
              child: Row(
                children: galleryUrls.asMap().entries.take(4).map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  final isSelected = safeIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPhotoIndex = index),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.secondary : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SmartNetworkImage(
                          url: url.isNotEmpty ? url : null,
                          fallback: fallbackForRoom(room.title, hotelId: widget.hotelId),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final isAuth =
        ref.read(authProvider).asData?.value.isAuthenticated ?? false;
    if (!isAuth) {
      context.go('/auth/login');
      return;
    }

    final isFav = ref.read(favoritesProvider).value
            ?.any((h) => h.hotelId == widget.hotelId) ??
        false;

    if (isFav) {
      final confirmed = await showUnfavoriteConfirmationDialog(context);
      if (!confirmed || !mounted) return;
      await ref.read(favoritesProvider.notifier).removeFavorite(widget.hotelId);
      if (mounted) await showFavoriteRemovedDialog(context);
    } else {
      await ref.read(favoritesProvider.notifier).addFavorite(widget.hotelId);
      if (mounted) await showFavoriteAddedDialog(context);
    }
  }

  Widget _buildAmenitiesGrid(List<Amenity> amenities) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(amenity.icon, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                amenity.label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHostSection(BuildContext context, Host host) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/hotel_details/${widget.hotelId}'),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHigh,
                ),
                child: ClipOval(
                  child: SmartNetworkImage(
                    url: host.imageUrl.isNotEmpty ? host.imageUrl : null,
                    fallback: fallbackForHotel(widget.hotelId),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.secondary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          host.rating,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          host.bio,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            context.push('/hotel_details/${widget.hotelId}');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Saiba Mais',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Room room) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: ContentMaxWidth.content),
            child: Row(
          children: [
            GestureDetector(
              onTap: () => _handleShareTap(room),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Icon(Icons.share_outlined, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _goToCheckout(room),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  elevation: 0,
                ),
                child: const Text(
                  'Reservar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

}
