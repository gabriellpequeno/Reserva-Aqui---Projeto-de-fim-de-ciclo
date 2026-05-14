import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/host_profile_provider.dart';
import '../widgets/desktop_profile_widgets.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class HostProfilePage extends ConsumerWidget {
  const HostProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(hostProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(context);

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
                  Icon(Icons.error_outline,
                      color: colorScheme.onSurface, size: 48),
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
            final name = (hotel['nome_hotel'] as String? ?? 'Sem nome');
            final email = (hotel['email'] as String? ?? 'Sem e-mail');
            final avatarUrl = (hotel['foto_perfil'] as String?) ??
                (fotos.isNotEmpty ? fotos.first['url'] as String? : null);

            return isDesktop
                ? _buildDesktop(context, ref, name, email, avatarUrl)
                : _buildMobile(context, ref, name, email, avatarUrl);
          },
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, String name,
      String email, String? avatarUrl) {
    return DesktopProfileScaffold(
      children: [
        DesktopProfileHero(
          name: name.toTitleCase(),
          email: email,
          avatarUrl: avatarUrl,
          subtitle: 'ANFITRIÃO',
          onEdit: () => context.push('/profile/host/edit'),
          onLogout: () async {
            await ref.read(authProvider.notifier).clear();
            if (context.mounted) context.go('/auth/login');
          },
        ),
        const SizedBox(height: 24),
        const SectionLabel(text: 'GESTÃO'),
        const SizedBox(height: 12),
        DesktopActionGrid(
          items: [
            DesktopActionItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              subtitle: 'Métricas e desempenho',
              onTap: () => context.go('/host/dashboard'),
            ),
            DesktopActionItem(
              icon: Icons.calendar_today_outlined,
              title: 'Agendamentos',
              subtitle: 'Reservas dos hóspedes',
              onTap: () => context.push('/host/agendamentos'),
            ),
            DesktopActionItem(
              icon: Icons.meeting_room_outlined,
              title: 'Meus quartos',
              subtitle: 'Catálogo e disponibilidade',
              onTap: () => context.push('/my_rooms'),
            ),
            DesktopActionItem(
              icon: Icons.notifications_none,
              title: 'Notificações',
              subtitle: 'Atualizações e alertas',
              onTap: () => context.go('/notifications'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel(text: 'SISTEMA'),
        const SizedBox(height: 12),
        DesktopActionGrid(
          items: [
            DesktopActionItem(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              subtitle: 'Preferências e tema',
              onTap: () => context.push('/profile/settings'),
            ),
            DesktopActionItem(
              icon: Icons.headset_mic_outlined,
              title: 'Suporte',
              subtitle: 'Fale com a equipe',
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: AppConstants.supportEmail,
                  queryParameters: {
                    'subject': 'Suporte ReservAqui',
                    'body': 'Olá, preciso de ajuda com...',
                  },
                );
                try {
                  await launchUrl(uri);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Copie o email: ${AppConstants.supportEmail}'),
                      action: SnackBarAction(
                        label: 'Copiar',
                        onPressed: () => Clipboard.setData(
                          ClipboardData(
                              text: AppConstants.supportEmail),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, String name,
      String email, String? avatarUrl) {
    return ResponsiveCenter(
      maxWidth: ContentMaxWidth.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 120),
            ProfileHeader(
              name: name.toTitleCase(),
              email: email,
              avatarUrl: avatarUrl,
              onEditTap: () => context.push('/profile/host/edit'),
            ),
            const SizedBox(height: 32),
            ProfileMenuSection(
              title: 'Atividade',
              items: [
                ProfileMenuItem(
                  title: 'Notificações',
                  icon: Icons.notifications_none,
                  onTap: () => context.go('/notifications'),
                ),
                ProfileMenuItem(
                  title: 'Agendamentos',
                  icon: Icons.calendar_today_outlined,
                  onTap: () => context.push('/host/agendamentos'),
                ),
                ProfileMenuItem(
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  onTap: () => context.go('/host/dashboard'),
                ),
                ProfileMenuItem(
                  title: 'Meus quartos',
                  icon: Icons.meeting_room_outlined,
                  onTap: () => context.push('/my_rooms'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ProfileMenuSection(
              title: 'Sistema',
              items: [
                ProfileMenuItem(
                  title: 'Configurações',
                  icon: Icons.settings_outlined,
                  onTap: () => context.push('/profile/settings'),
                ),
                ProfileMenuItem(
                  title: 'Suporte',
                  icon: Icons.headset_mic_outlined,
                  onTap: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: AppConstants.supportEmail,
                      queryParameters: {
                        'subject': 'Suporte ReservAqui',
                        'body': 'Olá, preciso de ajuda com...',
                      },
                    );
                    try {
                      await launchUrl(uri);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Copie o email: ${AppConstants.supportEmail}'),
                          action: SnackBarAction(
                            label: 'Copiar',
                            onPressed: () => Clipboard.setData(
                              ClipboardData(
                                  text: AppConstants.supportEmail),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Sair',
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
      ),
    );
  }
}
