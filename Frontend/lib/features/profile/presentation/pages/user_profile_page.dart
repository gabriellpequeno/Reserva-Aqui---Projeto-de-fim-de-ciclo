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
import '../../data/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/desktop_profile_widgets.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) => isDesktop
              ? _buildDesktop(context, ref, profile)
              : _buildMobile(context, ref, profile),
        ),
      ),
    );
  }

  Widget _buildDesktop(
      BuildContext context, WidgetRef ref, UserProfileModel profile) {
    return DesktopProfileScaffold(
      children: [
        DesktopProfileHero(
          name: profile.nomeCompleto.toTitleCase(),
          email: profile.email,
          avatarUrl: profile.fotoPerfil,
          onEdit: () => context.push('/profile/user/edit'),
          onLogout: () async {
            await ref.read(authProvider.notifier).clear();
            if (context.mounted) context.go('/auth/login');
          },
        ),
        const SizedBox(height: 24),
        const SectionLabel(text: 'ATIVIDADE'),
        const SizedBox(height: 12),
        DesktopActionGrid(
          items: [
            DesktopActionItem(
              icon: Icons.notifications_none,
              title: 'Notificações',
              subtitle: 'Atualizações da sua reserva',
              onTap: () => context.go('/notifications'),
            ),
            DesktopActionItem(
              icon: Icons.confirmation_number_outlined,
              title: 'Meus tickets',
              subtitle: 'Reservas ativas e histórico',
              onTap: () => context.go('/tickets'),
            ),
            DesktopActionItem(
              icon: Icons.favorite_border,
              title: 'Favoritos',
              subtitle: 'Hotéis salvos',
              onTap: () => context.go('/favorites'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel(text: 'SISTEMA'),
        const SizedBox(height: 16),
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
              onTap: () => _openEmail(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openEmail(BuildContext context) async {
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
          content: Text('Copie o email: ${AppConstants.supportEmail}'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () => Clipboard.setData(
              ClipboardData(text: AppConstants.supportEmail),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMobile(
      BuildContext context, WidgetRef ref, UserProfileModel profile) {
    return ResponsiveCenter(
      maxWidth: ContentMaxWidth.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 120),
            ProfileHeader(
              name: profile.nomeCompleto.toTitleCase(),
              email: profile.email,
              avatarUrl: profile.fotoPerfil,
              onEditTap: () => context.push('/profile/user/edit'),
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
                  title: 'Meus Tickets',
                  icon: Icons.confirmation_number_outlined,
                  onTap: () => context.go('/tickets'),
                ),
                ProfileMenuItem(
                  title: 'Favoritos',
                  icon: Icons.favorite_border,
                  onTap: () => context.go('/favorites'),
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
                  onTap: () => _openEmail(context),
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
