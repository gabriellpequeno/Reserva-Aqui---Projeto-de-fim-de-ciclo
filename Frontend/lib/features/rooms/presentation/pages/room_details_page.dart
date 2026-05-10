import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../domain/models/room.dart';
import '../notifiers/room_details_notifier.dart';
import '../widgets/availability_checker.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

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

  // Datas escolhidas no AvailabilityChecker — propagadas ao checkout via queryParam
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // null = usa estado do provider; true/false = override otimista local do favorito
  bool? _favoriteOptimistic;

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
    ref.watch(favoritesProvider); // garante rebuild quando favoritos mudam
    final colorScheme = Theme.of(context).colorScheme;

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
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(
                              roomState.room!,
                              isFavorite: _favoriteOptimistic ??
                                  ref.read(favoritesProvider.notifier).isFavorite(widget.hotelId),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => context.push('/hotel_details/${widget.hotelId}'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roomState.room!.hotelName,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        roomState.room!.title,
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
                                _buildAmenitiesGrid(roomState.room!.amenities),
                                if (roomState.categoriaId > 0)
                                  AvailabilityChecker(
                                    hotelId: widget.hotelId,
                                    categoriaId: roomState.categoriaId,
                                    onDatesChanged: (ci, co) => setState(() {
                                      _checkInDate = ci;
                                      _checkOutDate = co;
                                    }),
                                  ),
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
                                  roomState.room!.description,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildHostSection(context, roomState.room!.host),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomBar(context, roomState.room!),
                  ],
                ),
    );
  }

  Widget _buildImageSection(Room room, {required bool isFavorite}) {
    // When no real photos, fill gallery with 4 deterministic room mocks for this hotel
    final galleryUrls = room.imageUrls.isNotEmpty
        ? room.imageUrls
        : fallbacksForRoom(room.title, widget.hotelId, 4);
    final safeIndex = _currentPhotoIndex.clamp(0, galleryUrls.length - 1);
    final mainImageUrl = galleryUrls[safeIndex];

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
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
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
                        const Text(
                          '\$',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          '${room.price.toInt()}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                    const FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'por dia',
                        style: TextStyle(
                          color: AppColors.secondary,
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
    final authValue = ref.read(authProvider).value;
    if (!(authValue?.isAuthenticated ?? false)) {
      context.go('/auth/login');
      return;
    }

    final notifier = ref.read(favoritesProvider.notifier);
    final wasFavorite = notifier.isFavorite(widget.hotelId);
    setState(() => _favoriteOptimistic = !wasFavorite);

    try {
      if (wasFavorite) {
        await notifier.removeFavorite(widget.hotelId);
      } else {
        await notifier.addFavorite(widget.hotelId);
      }
      if (mounted) setState(() => _favoriteOptimistic = null);
    } catch (_) {
      if (mounted) {
        setState(() => _favoriteOptimistic = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasFavorite ? 'Erro ao remover dos favoritos' : 'Erro ao adicionar aos favoritos',
            ),
          ),
        );
      }
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
                onPressed: () {
                  final roomState = ref.read(roomDetailsNotifierProvider);
                  final base = '/booking/checkout/${widget.hotelId}/${roomState.categoriaId}/${room.id}';
                  String url = base;
                  if (_checkInDate != null && _checkOutDate != null) {
                    final ci = _fmtDateIso(_checkInDate!);
                    final co = _fmtDateIso(_checkOutDate!);
                    url = '$base?checkin=$ci&checkout=$co';
                  }
                  context.push(url);
                },
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
    );
  }

  String _fmtDateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
