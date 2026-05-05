import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';
import '../providers/host_profile_provider.dart';

class HostProfilePage extends ConsumerWidget {
  const HostProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(hostProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: profileState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onSurface,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar perfil:\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Tentar novamente',
                    onPressed: () => ref.invalidate(hostProfileProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final hotel = data.hotel;
            final fotos = data.fotos;

            final name = hotel['nome_hotel'] ?? 'Sem nome';
            final email = hotel['email'] ?? 'Sem e-mail';
            final avatarUrl = fotos.isNotEmpty ? fotos.first['url'] : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  ProfileHeader(
                    name: name,
                    email: email,
                    avatarUrl: avatarUrl,
                    onEditTap: () => context.push('/profile/host/edit'),
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
                    onPressed: () async {
                      await ref.read(authProvider.notifier).clear();
                      if (context.mounted) context.go('/auth/login');
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
