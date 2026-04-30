import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Número de hóspedes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
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
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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
            style: const TextStyle(color: AppColors.greyText, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }
}
