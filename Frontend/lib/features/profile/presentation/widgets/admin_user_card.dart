import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/admin_user_model.dart';
import 'admin_account_status_chip.dart';

/// Card de usuário (hóspede) na tela de gerenciamento de contas.
class AdminUserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onEdit;

  const AdminUserCard({super.key, required this.user, required this.onEdit});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nome.isEmpty ? '(sem nome)' : user.nome,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                AdminAccountStatusChip(status: user.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Editar ${user.nome}',
            button: true,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE8DB),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = user.fotoUrl;
    final decoration = BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      image: url != null
          ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
          : null,
    );
    return Container(
      width: 48,
      height: 48,
      decoration: decoration,
      alignment: Alignment.center,
      child: url == null
          ? Text(
              _initials(user.nome),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
