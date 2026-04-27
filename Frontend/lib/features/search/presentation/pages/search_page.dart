import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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

          // Search Results or Messages
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : searchState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              searchState.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  ref.read(searchProvider.notifier).performSearch(),
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : searchState.results.isEmpty && searchState.hasSearched
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhum quarto encontrado',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                if (searchState.selectedAmenityIds.isNotEmpty || searchState.guests != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Tente ajustar seus filtros',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : !searchState.hasSearched
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Busque quartos para começar',
                                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 800) {
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(24),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.8,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: searchState.results.length,
                                      itemBuilder: (context, index) =>
                                          _buildRoomCard(context, searchState.results[index]),
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(24),
                                    itemCount: searchState.results.length,
                                    itemBuilder: (context, index) =>
                                        _buildRoomCard(context, searchState.results[index]),
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
                  hint: 'Hóspedes',
                  value: state.guests != null ? '${state.guests}' : null,
                  onTap: () => _showGuestPicker(context, ref, state),
                ),
              ),
              const SizedBox(width: 12),
              // Dates
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, ref, state),
                  child: _buildSearchInput(
                    icon: Icons.calendar_month,
                    hint: 'Datas',
                    value: state.dateRange != null
                        ? _formatDateRange(state.dateRange!)
                        : null,
                  ),
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

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('dd/MM/yy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  Future<void> _showDatePicker(
      BuildContext context, WidgetRef ref, SearchState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: state.dateRange,
    );
    if (picked != null) {
      ref.read(searchProvider.notifier).updateDateRange(picked);
    }
  }

  Future<void> _showGuestPicker(
      BuildContext context, WidgetRef ref, SearchState state) async {
    int guests = state.guests ?? 1;
    await showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quantos hóspedes?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: guests > 1
                        ? () => setModalState(() => guests--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$guests',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: guests < 20
                        ? () => setModalState(() => guests++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(searchProvider.notifier).updateGuests(null);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(searchProvider.notifier).updateGuests(guests);
                        Navigator.pop(context);
                      },
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, dynamic room) {
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
              // Room Image
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: room.imageUrl != null
                      ? Image.network(
                          room.imageUrl!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              // Room Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.nomeHotel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '${room.cidade}, ${room.uf}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room.precoDiaria,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (room.rating != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${room.rating!.toStringAsFixed(1)} (${room.reviewCount})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Sem avaliações',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Amenities Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: room.amenities
                            .take(3)
                            .map((a) => _buildAmenityChip(a.nome))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      // Action Button
                      ElevatedButton(
                        onPressed: () =>
                            context.push('/room_details/${room.roomId}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                          elevation: 0,
                        ),
                        child: const Text('Ver Mais',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildImagePlaceholder() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey.shade200,
      child: const Icon(Icons.bed, size: 60, color: Colors.grey),
    );
  }

  Widget _buildAmenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
