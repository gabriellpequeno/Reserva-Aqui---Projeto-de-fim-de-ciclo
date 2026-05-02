import 'package:flutter/material.dart';
import '../../domain/models/admin_account_status.dart';

/// Chip colorido que indica o status de uma conta (ativo / suspenso / inativo).
class AdminAccountStatusChip extends StatelessWidget {
  final AdminAccountStatus status;

  const AdminAccountStatusChip({super.key, required this.status});

  ({Color bg, Color fg, String label}) _visualsFor(AdminAccountStatus s) {
    switch (s) {
      case AdminAccountStatus.ativo:
        return (
          bg: Colors.green.withValues(alpha: 0.15),
          fg: Colors.green.shade800,
          label: 'Ativo',
        );
      case AdminAccountStatus.suspenso:
        return (
          bg: Colors.red.withValues(alpha: 0.12),
          fg: Colors.red.shade700,
          label: 'Suspenso',
        );
      case AdminAccountStatus.inativo:
        return (
          bg: Colors.grey.withValues(alpha: 0.18),
          fg: Colors.grey.shade700,
          label: 'Inativo',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visualsFor(status);
    return Semantics(
      label: 'Status: ${v.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: v.bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          v.label,
          style: TextStyle(
            color: v.fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
