import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 120),
              ProfileHeader(
                name: 'Admin',
                email: 'admin@admin.com',
                onEditTap: () => context.push('/profile/admin/edit'),
              ),
              const SizedBox(height: 32),
              ProfileMenuSection(
                title: 'Atividade',
                items: [
                  ProfileMenuItem(
                    title: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    onTap: () => context.go('/admin/dashboard'),
                  ),
                  ProfileMenuItem(
                    title: 'Clientes',
                    icon: Icons.people_outline,
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileMenuSection(
                title: 'sistema',
                items: [
                  ProfileMenuItem(
                    title: 'configurações',
                    icon: Icons.settings_outlined,
                    onTap: () {
                      context.push('/profile/settings');
                    },
                  ),
                  ProfileMenuItem(
                    title: 'suporte',
                    icon: Icons.headset_mic_outlined,
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'sair',
                color: AppColors.secondary,
                textColor: AppColors.primary,
                onPressed: () => context.go('/auth'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
