import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../domain/models/room.dart';
import '../notifiers/room_details_notifier.dart';
import '../widgets/availability_checker.dart';

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
    // Gatilho de carregamento: dispara loadRoom ao montar a tela com hotelId e roomId
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado para a área de transferência')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomDetailsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: roomState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar detalhes do quarto',
                        style: TextStyle(color: Colors.grey[600]),
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
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
                    child: Stack(
                      children: [
                        isTablet(context)
                            ? SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildImageSection(roomState.room!),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () => context.push('/hotel_details/${widget.hotelId}'),
                                              child: Text(
                                                roomState.room!.hotelName,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            const Text(
                                              'Comodidades',
                                              style: TextStyle(
                                                color: AppColors.primary,
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
                                              ),
                                            const SizedBox(height: 32),
                                            const Text(
                                              'Detalhes',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              roomState.room!.description,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 32),
                                            _buildHostSection(context, roomState.room!.host),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildImageSection(roomState.room!),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => context.push('/hotel_details/${widget.hotelId}'),
                                            child: Text(
                                              roomState.room!.hotelName,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Comodidades',
                                            style: TextStyle(
                                              color: AppColors.primary,
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
                                            ),
                                          const SizedBox(height: 32),
                                          const Text(
                                            'Detalhes',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            roomState.room!.description,
                                            style: const TextStyle(
                                              color: AppColors.primary,
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
                  ),
                ),
    );
  }

  Widget _buildImageSection(Room room) {
    final mainImageUrl = room.imageUrls.isNotEmpty
        ? room.imageUrls[_currentPhotoIndex]
        : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=800';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Image — atualizada conforme thumbnail selecionada
        Container(
          height: 400,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(mainImageUrl),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),

        // Gradient Top Overlay
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

        // Back Button
        Positioned(
          top: 50,
          left: 20,
          child: _buildCircularButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
          ),
        ),

        // Floating Price Tag — sangra à esquerda, centro vertical na borda da imagem
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
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.centerLeft,
                      child: const Text(
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

        // Carrossel de fotos — centro vertical alinhado à borda inferior da imagem
        if (room.imageUrls.length > 1)
          Positioned(
            bottom: 0,
            right: 24,
            child: FractionalTranslation(
              translation: const Offset(0, 0.5),
              child: Row(
                children: room.imageUrls.asMap().entries.take(4).map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  final isSelected = _currentPhotoIndex == index;
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
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
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

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAmenitiesGrid(List<Amenity> amenities) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(amenity.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                amenity.label,
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

  Widget _buildHostSection(BuildContext context, Host host) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toque no avatar ou no nome do hotel navega para hotel_details
        GestureDetector(
          onTap: () => context.push('/hotel_details/${widget.hotelId}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD9D9D9),
                backgroundImage: host.imageUrl.isNotEmpty
                    ? NetworkImage(host.imageUrl)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.name,
                      style: const TextStyle(
                        color: AppColors.primary,
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
                          style: const TextStyle(color: AppColors.greyText, fontSize: 12),
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
          style: const TextStyle(
            color: AppColors.primary,
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Share Button
            GestureDetector(
              onTap: () => _handleShareTap(room),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.share_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            // Reservation Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final roomState = ref.read(roomDetailsNotifierProvider);
                  context.push(
                    '/booking/checkout/${widget.hotelId}/${roomState.categoriaId}/${room.id}',
                  );
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
}
