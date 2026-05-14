import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../home/presentation/widgets/room_card.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  final Set<String>? initialAmenities;

  const SearchPage({super.key, this.initialQuery, this.initialAmenities});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _destinationController = TextEditingController();
  bool _isFilterOpen = false;
  final Set<String> _selectedFilters = {};

  static const _filterOptions = [
    'Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Piscina', 'Academia',
    'Spa', 'Restaurante', 'Bar', 'Cama king-size', 'Cama queen-size',
    'Varanda', 'Banheira', 'Frigobar', 'Salão de eventos',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmenities != null && widget.initialAmenities!.isNotEmpty) {
      _selectedFilters.addAll(widget.initialAmenities!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedFilters.isNotEmpty) {
        ref.read(searchProvider.notifier).updateAmenities(_selectedFilters.toList());
      }
      final query = widget.initialQuery;
      if (query != null && query.isNotEmpty) {
        _destinationController.text = query;
        ref.read(searchProvider.notifier).updateDestination(query);
        ref.read(searchProvider.notifier).performSearch();
      }
    });
  }

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

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => ref.read(searchProvider.notifier).hideAllPickers(),
      child: Scaffold(
        body: ResponsiveCenter(
          maxWidth: ContentMaxWidth.content,
          child: Column(
          children: [
            _buildSearchHeader(context, searchState),
            Container(
              height: 1,
              color: colorScheme.outline,
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
                            final cardWidth = constraints.maxWidth - 48.0;
                            final bottomPad = MediaQuery.of(context).padding.bottom + 104;
                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad),
                              itemCount: searchState.results.length,
                              itemBuilder: (context, index) {
                                final hotel = searchState.results[index];
                                final cardTitle = [
                                  if (hotel.title.isNotEmpty) hotel.title,
                                  if (hotel.hotelName.isNotEmpty) hotel.hotelName,
                                ].join(' - ');
                                return RoomCard(
                                  roomId: hotel.id,
                                  hotelId: hotel.hotelId,
                                  title: cardTitle,
                                  imageUrl: hotel.imageUrl,
                                  rating: hotel.rating,
                                  amenities: hotel.amenities,
                                  price: hotel.price > 0 ? hotel.price : null,
                                  cardWidth: cardWidth,
                                  cardHeight: 220,
                                  cardMargin: const EdgeInsets.only(bottom: 16),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, SearchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final range = state.dateRange;
    final dateLabel = range != null
        ? '${_fmt(range.start)} → ${_fmt(range.end)}'
        : null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 50,
        24,
        24,
      ),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo centralizado com notificação à direita
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SvgPicture.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'lib/assets/icons/logo/logoDark.svg'
                      : 'lib/assets/icons/logo/logo.svg',
                  height: 32,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Icon(
                    Icons.notifications_none,
                    color: colorScheme.onSurface,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildDestinationField(state),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildGuestsField(state),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildDateField(context, state, dateLabel),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      ref.read(searchProvider.notifier).performSearch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _selectedFilters.isNotEmpty
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainer,
                  border: Border.all(
                    color: _selectedFilters.isNotEmpty
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _selectedFilters.isNotEmpty
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  onPressed: () =>
                      setState(() => _isFilterOpen = !_isFilterOpen),
                ),
              ),
            ],
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isFilterOpen ? _buildFilterPanel() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comodidades',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _filterOptions.map((option) {
              final isSelected = _selectedFilters.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilters.add(option);
                    } else {
                      _selectedFilters.remove(option);
                    }
                  });
                  ref.read(searchProvider.notifier).updateAmenities(_selectedFilters.toList());
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          if (_selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _selectedFilters.clear());
                ref.read(searchProvider.notifier).updateAmenities([]);
              },
              child: const Text(
                'Limpar filtros',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Campo destino com dropdown de sugestões ──────────────────────────────

  Widget _buildDestinationField(SearchState state) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Para Onde Você Vai?',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
          color: colorScheme.outline,
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
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                        if (location.isNotEmpty)
                          Text(location,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
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
                  color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 200,
      decoration: _dropdownDecoration(),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 20,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colorScheme.outline,
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
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person,
                      size: 16,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      count == 1 ? '1 hóspede' : '$count hóspedes',
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.primary
                            : (colorScheme.onSurface),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check,
                        size: 16, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: dateLabel != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontSize: dateLabel != null ? 12 : 13,
                  fontWeight: dateLabel != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
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
      builder: (context, child) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child!,
        ),
      ),
    );
    if (picked != null && context.mounted) {
      ref.read(searchProvider.notifier).updateDateRange(picked);
    }
  }

  // ── Helpers visuais ───────────────────────────────────────────────────────

  Widget _inputBox({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }

  BoxDecoration _dropdownDecoration() {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: colorScheme.outline),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Encontre o lugar perfeito',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
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
