import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/admin_account_status.dart';

/// Bottom sheet para alternar o status de uma conta (usuário ou hotel).
///
/// Recebe o status atual, os status permitidos para aquele tipo de conta
/// e um callback `onConfirm`. Retorna o novo status selecionado via `.pop()`
/// ou `null` se cancelado.
class AdminEditAccountSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final AdminAccountStatus currentStatus;
  final List<AdminAccountStatus> allowedStatuses;

  const AdminEditAccountSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStatus,
    required this.allowedStatuses,
  });

  static Future<AdminAccountStatus?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required AdminAccountStatus currentStatus,
    required List<AdminAccountStatus> allowedStatuses,
  }) {
    return showModalBottomSheet<AdminAccountStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AdminEditAccountSheet(
        title: title,
        subtitle: subtitle,
        currentStatus: currentStatus,
        allowedStatuses: allowedStatuses,
      ),
    );
  }

  @override
  State<AdminEditAccountSheet> createState() => _AdminEditAccountSheetState();
}

class _AdminEditAccountSheetState extends State<AdminEditAccountSheet> {
  late AdminAccountStatus _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
  }

  String _labelFor(AdminAccountStatus s) {
    switch (s) {
      case AdminAccountStatus.ativo:
        return 'Ativo';
      case AdminAccountStatus.suspenso:
        return 'Suspenso';
      case AdminAccountStatus.inativo:
        return 'Inativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _selected != widget.currentStatus;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.strokeLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: const TextStyle(color: AppColors.greyText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text(
            'Status da conta',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.allowedStatuses.map(
            (s) => RadioListTile<AdminAccountStatus>(
              title: Text(_labelFor(s)),
              value: s,
              groupValue: _selected,
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _selected = v ?? _selected),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: dirty
                      ? () => Navigator.of(context).pop(_selected)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.strokeLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
