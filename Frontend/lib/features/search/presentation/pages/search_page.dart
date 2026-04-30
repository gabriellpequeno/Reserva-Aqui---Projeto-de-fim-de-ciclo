import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorites/domain/models/favorite_room.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    ref.listen<SearchState>(searchProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return GestureDetector(
      onTap: () => ref.read(searchProvider.notifier).hideAllPickers(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildSearchHeader(context, searchState),
            Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.1),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              child: searchState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.secondary),
                    )
                  : searchState.results.isEmpty
                      ? _buildInitialState()
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
                                    _buildHotelCard(
                                        context, searchState.results[index]),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: searchState.results.length,
                              itemBuilder: (context, index) =>
                                  _buildHotelCard(
                                      context, searchState.results[index]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, SearchState state) {
    final range = state.dateRange;
    final dateLabel = range != null
        ? '${_fmt(range.start)} → ${_fmt(range.end)}'
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + notificações
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: SvgPicture.asset(
                  'lib/assets/icons/logo/logo.svg',
                  height: 32,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Campo destino + dropdown de sugestões
          _buildDestinationField(state),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo hóspedes com lista cascata
              Expanded(
                flex: 2,
                child: _buildGuestsField(state),
              ),
              const SizedBox(width: 12),
              // Campo data único (check-in + check-out)
              Expanded(
                flex: 3,
                child: _buildDateField(context, state, dateLabel),
              ),
            ],
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(searchProvider.notifier).performSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
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

  // ── Campo destino com dropdown de sugestões ──────────────────────────────

  Widget _buildDestinationField(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputBox(
          child: Row(
            children: [
              const Icon(Icons.location_on,
                  color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  onChanged: (val) => ref
                      .read(searchProvider.notifier)
                      .updateDestination(val),
                  onSubmitted: (_) =>
                      ref.read(searchProvider.notifier).performSearch(),
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Para Onde Você Vai?',
                    hintStyle: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(searchProvider.notifier).fetchSuggestions(),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  state.showSuggestions
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ),
        if (state.showSuggestions && state.suggestions.isNotEmpty)
          _dropdownSuggestions(state.suggestions),
      ],
    );
  }

  Widget _dropdownSuggestions(List<String> suggestions) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: _dropdownDecoration(),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.2),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) {
          final label = suggestions[i];
          final parts = label.split(' — ');
          final hotelName = parts.first;
          final location = parts.length > 1 ? parts[1] : '';
          return InkWell(
            onTap: () {
              ref.read(searchProvider.notifier).selectSuggestion(
                    label,
                    (val) => _destinationController.text = val,
                  );
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotelName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                        if (location.isNotEmpty)
                          Text(location,
                              style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Campo hóspedes com lista cascata (1-20) ───────────────────────────────

  Widget _buildGuestsField(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              ref.read(searchProvider.notifier).toggleGuestsPicker(),
          child: _inputBox(
            child: Row(
              children: [
                const Icon(Icons.person,
                    color: AppColors.secondary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.guests == 1
                        ? '1 Hóspede'
                        : '${state.guests} Hóspedes',
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  state.showGuestsPicker
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: AppColors.greyText,
                ),
              ],
            ),
          ),
        ),
        if (state.showGuestsPicker) _buildGuestsList(state.guests),
      ],
    );
  }

  Widget _buildGuestsList(int selected) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 200,
      decoration: _dropdownDecoration(),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 20,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.2),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) {
          final count = i + 1;
          final isSelected = count == selected;
          return InkWell(
            onTap: () {
              ref.read(searchProvider.notifier).updateGuests(count);
              ref.read(searchProvider.notifier).hideAllPickers();
            },
            child: Container(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.greyText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      count == 1 ? '1 hóspede' : '$count hóspedes',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.greyText,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check,
                        size: 16, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Campo data único (abre DateRangePicker como Dialog compacto) ──────────

  Widget _buildDateField(
      BuildContext context, SearchState state, String? dateLabel) {
    return GestureDetector(
      onTap: () => _openDateRangePicker(context, state.dateRange),
      child: _inputBox(
        child: Row(
          children: [
            const Icon(Icons.calendar_month,
                color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateLabel ?? 'Check-in → Check-out',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontSize: dateLabel != null ? 12 : 13,
                  fontWeight: dateLabel != null
                      ? FontWeight.w600
                      : FontWeight.w400,
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

  Future<void> _openDateRangePicker(
      BuildContext context, DateTimeRange? current) async {
    ref.read(searchProvider.notifier).hideAllPickers();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: current,
      helpText: 'Selecione as datas',
      saveText: 'Confirmar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ),
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: child!,
          ),
        ),
      ),
    );
    if (picked != null && context.mounted) {
      ref.read(searchProvider.notifier).updateDateRange(picked);
    }
  }

  // ── Helpers visuais ───────────────────────────────────────────────────────

  Widget _inputBox({required Widget child}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFB5B5B5)),
      ),
      child: child,
    );
  }

  BoxDecoration _dropdownDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFB5B5B5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Resultado: card de hotel ──────────────────────────────────────────────

  Widget _buildHotelCard(BuildContext context, FavoriteRoom hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                hotel.imageUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'lib/assets/images/home_page.jpeg',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
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
                  if (hotel.destination.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      hotel.destination,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (hotel.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hotel.amenities
                          .map((icon) => _amenityTag(icon))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .push('/room_details/${hotel.hotelId}/${hotel.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ver Mais',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityTag(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Encontre o lugar perfeito',
            style: TextStyle(color: AppColors.greyText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = (date.year % 100).toString().padLeft(2, '0');
    return '$d/$m/$y';
  }
}
