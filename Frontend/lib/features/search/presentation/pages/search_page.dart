import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorites/domain/models/favorite_room.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with search inputs
          _buildSearchHeader(context, ref, searchState),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),

          // Search Results
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : searchState.results.isEmpty
                    ? _buildInitialState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: searchState.results.length,
                              itemBuilder: (context, index) => _buildHotelCard(context, searchState.results[index]),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: searchState.results.length,
                            itemBuilder: (context, index) => _buildHotelCard(context, searchState.results[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, WidgetRef ref, SearchState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Logo and Notification Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48), // Balance bell icon
              Expanded(
                child: SvgPicture.asset(
                  'lib/assets/icons/logo/logo.svg',
                  height: 32,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // "Para onde você vai?"
          _buildSearchInput(
            icon: Icons.location_on,
            hint: 'Para Onde Você Vai?',
            value: state.destination,
            onChanged: (val) => ref.read(searchProvider.notifier).updateDestination(val),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Guests
              Expanded(
                flex: 2,
                child: _buildSearchInput(
                  icon: Icons.person,
                  hint: 'Hospedes',
                  value: state.guests > 0 ? '${state.guests} Hospedes' : 'Hospedes',
                  onTap: () {
                    // Show guests picker
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Dates
              Expanded(
                flex: 3,
                child: _buildSearchInput(
                  icon: Icons.calendar_month,
                  hint: 'Data',
                  value: '14/04/26 - 15/04/26', // Mocked as in prototype
                  onTap: () {
                    // Show date picker
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Button
          ElevatedButton(
            onPressed: () => ref.read(searchProvider.notifier).performSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            child: const Text(
              'Buscar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required IconData icon,
    required String hint,
    String? value,
    Function(String)? onChanged,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFB5B5B5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: onChanged != null
                  ? TextField(
                      onChanged: onChanged,
                      style: const TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 14, fontWeight: FontWeight.w700),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Text(
                      value ?? hint,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, FavoriteRoom hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel Image
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'lib/assets/images/home_page.jpeg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Hotel Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.hotelName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Amenities Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildAmenityTag('wifi', Icons.wifi),
                          _buildAmenityTag('2 camas', Icons.king_bed_outlined),
                          _buildAmenityTag('café da manhã', Icons.flatware),
                          _buildAmenityTag('ar condicionado', Icons.air),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action Button
                      ElevatedButton(
                        onPressed: () => context.push('/room_details/${hotel.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          elevation: 0,
                        ),
                        child: const Text('Ver Mais', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text(
            'Encontre o lugar perfeito',
            style: TextStyle(color: AppColors.greyText, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
