import 'package:flutter/material.dart';
import '../../domain/models/catalogo_item.dart';

/// Widget isolado para seleção de comodidades.
/// Gerencia seu próprio estado de seleção — o formulário pai não rebuild ao
/// tocar em um chip; só recebe notificação via [onToggle].
class AmenitiesSelector extends StatefulWidget {
  final List<CatalogoItemModel> itens;

  /// Chamado ao selecionar/desselecionar um item: (id, isSelected).
  final void Function(int id, bool selected) onToggle;

  const AmenitiesSelector({
    super.key,
    required this.itens,
    required this.onToggle,
  });

  @override
  State<AmenitiesSelector> createState() => _AmenitiesSelectorState();
}

class _AmenitiesSelectorState extends State<AmenitiesSelector> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grupos = <String, List<CatalogoItemModel>>{};
    for (final item in widget.itens) {
      grupos.putIfAbsent(item.categoria, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: grupos.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: entry.value.map((item) {
                final isSelected = _selected.contains(item.id);
                return FilterChip(
                  label: Text(item.nome),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selected.add(item.id);
                      } else {
                        _selected.remove(item.id);
                      }
                    });
                    widget.onToggle(item.id, val);
                  },
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? colorScheme.primary : colorScheme.outline,
                    ),
                  ),
                  backgroundColor: colorScheme.surface,
                  showCheckmark: true,
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }
}
