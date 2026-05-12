import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
          data: (profile) => ResponsiveCenter(
            maxWidth: ContentMaxWidth.profile,
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 120),
                ProfileHeader(
                  name: profile.nomeCompleto,
                  email: profile.email,
                  avatarUrl: profile.fotoPerfil,
                  onEditTap: () => context.push('/profile/user/edit'),
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
                      title: 'meus tickets',
                      icon: Icons.confirmation_number_outlined,
                      onTap: () => context.go('/tickets'),
                    ),
                    ProfileMenuItem(
                      title: 'favoritos',
                      icon: Icons.favorite_border,
                      onTap: () => context.go('/favorites'),
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
                      onTap: () => context.push('/profile/settings'),
                    ),
                    ProfileMenuItem(
                      title: 'suporte',
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
                      },
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
          ),
          ),
        ),
      ),
    );
  }
}
