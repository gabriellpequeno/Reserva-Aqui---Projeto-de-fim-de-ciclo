import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/admin_hotel_model.dart';
import 'admin_account_status_chip.dart';

/// Card de hotel (anfitrião) na tela de gerenciamento de contas.
class AdminHotelCard extends StatelessWidget {
  final AdminHotelModel hotel;
  final VoidCallback onEdit;

  const AdminHotelCard({super.key, required this.hotel, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              bottomLeft: Radius.circular(11),
            ),
            child: _buildThumb(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.nome.isEmpty ? '(sem nome)' : hotel.nome,
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
                    hotel.emailResponsavel,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  AdminAccountStatusChip(status: hotel.status),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              label: 'Editar ${hotel.nome}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    final url = hotel.capaUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.bgSecondary,
      child: const Icon(Icons.hotel, color: AppColors.greyText, size: 32),
    );
  }
}
