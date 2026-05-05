import 'package:flutter/material.dart';

class GuestsPickerSheet extends StatefulWidget {
  const GuestsPickerSheet({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<GuestsPickerSheet> createState() => _GuestsPickerSheetState();
}

class _GuestsPickerSheetState extends State<GuestsPickerSheet> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue.clamp(1, 20);
  }

  void _decrement() {
    if (_count <= 1) return;
    setState(() => _count--);
    widget.onChanged(_count);
  }

  void _increment() {
    if (_count >= 20) return;
    setState(() => _count++);
    widget.onChanged(_count);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Número de hóspedes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                icon: Icons.remove,
                onTap: _count > 1 ? _decrement : null,
              ),
              const SizedBox(width: 32),
              Text(
                '$_count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 32),
              _CounterButton(
                icon: Icons.add,
                onTap: _count < 20 ? _increment : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _count == 1 ? '1 hóspede' : '$_count hóspedes',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
