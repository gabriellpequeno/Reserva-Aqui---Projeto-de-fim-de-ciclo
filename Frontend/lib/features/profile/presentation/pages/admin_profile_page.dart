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
import '../providers/admin_profile_provider.dart';
import '../widgets/desktop_profile_widgets.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(adminProfileProvider);
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: asyncProfile.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
          error: (err, _) => _buildError(
            context: context,
            message: err.toString(),
            onRetry: () => ref.invalidate(adminProfileProvider),
          ),
          data: (profile) {
            final name =
                profile.nome.isEmpty ? 'Admin' : profile.nome.toTitleCase();
            return isDesktop
                ? _buildDesktop(context, ref, name, profile.email)
                : _buildMobile(context, ref, name, profile.email);
          },
        ),
      ),
    );
  }

  Widget _buildDesktop(
      BuildContext context, WidgetRef ref, String name, String email) {
    return DesktopProfileScaffold(
      children: [
        DesktopProfileHero(
          name: name,
          email: email,
          subtitle: 'ADMINISTRADOR',
          onEdit: () => context.push('/profile/admin/edit'),
          onLogout: () async {
            await ref.read(authProvider.notifier).clear();
            if (context.mounted) context.go('/auth/login');
          },
        ),
        const SizedBox(height: 24),
        const SectionLabel(text: 'PAINEL'),
        const SizedBox(height: 12),
        DesktopActionGrid(
          items: [
            DesktopActionItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              subtitle: 'Visão geral da plataforma',
              onTap: () => context.go('/admin/dashboard'),
            ),
            DesktopActionItem(
              icon: Icons.people_outline,
              title: 'Clientes',
              subtitle: 'Gerenciar usuários e hotéis',
              onTap: () => context.push('/admin/accounts'),
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

  Widget _buildMobile(
      BuildContext context, WidgetRef ref, String name, String email) {
    return ResponsiveCenter(
      maxWidth: ContentMaxWidth.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 120),
            ProfileHeader(
              name: name,
              email: email,
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
                  onTap: () => context.push('/admin/accounts'),
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

  Widget _buildError({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: colorScheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o perfil.\n$message',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
