import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class HostProfilePage extends StatelessWidget {
  const HostProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 120),
              ProfileHeader(
                name: 'Acesse agora',
                email: 'usuario@user.com',
                onEditTap: () {},
              ),
              const SizedBox(height: 32),
              ProfileMenuSection(
                title: 'Atividade',
                items: [
                  ProfileMenuItem(
                    title: 'notificações',
                    icon: Icons.notifications_none,
                    onTap: () => context.go('/notifications'),
                  ),
                  ProfileMenuItem(
                    title: 'Agendamentos',
                    icon: Icons.calendar_today_outlined,
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    title: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    onTap: () => context.go('/host/dashboard'),
                  ),
                  ProfileMenuItem(
                    title: 'Meus quartos',
                    icon: Icons.meeting_room_outlined,
                    onTap: () {
                      context.push('/my_rooms');
                    },
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
