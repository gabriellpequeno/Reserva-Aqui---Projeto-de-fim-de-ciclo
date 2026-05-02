import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/admin_profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(adminProfileProvider);

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
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 120),
                ProfileHeader(
                  name: profile.nome.isEmpty ? 'Admin' : profile.nome,
                  email: profile.email,
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
                    if (context.mounted) {
                      context.go('/auth/login');
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.greyText,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o perfil.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
