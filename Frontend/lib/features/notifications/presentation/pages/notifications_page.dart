import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/app_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isLoggedIn =
        ref.watch(authProvider).asData?.value.isAuthenticated ?? false;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, ref),
          Expanded(
            child: !isLoggedIn
                ? _buildLoginMessage(context)
                : notificationsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => const Center(
                      child: Text('Erro ao carregar notificações'),
                    ),
                    data: (notifications) => notifications.isEmpty
                        ? _buildEmptyState(context)
                        : Stack(
                            children: [
                              ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 24, 24, 100),
                                itemCount: notifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildNotificationCard(
                                    context,
                                    ref,
                                    notifications[index],
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 30,
                                left: 0,
                                right: 0,
                                child: Center(
                                    child: _buildClearButton(context, ref)),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 32),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  final auth = ref.read(authProvider).asData?.value;
                  if (auth?.role == AuthRole.host) {
                    context.go('/profile/host');
                  } else {
                    context.go('/profile/user');
                  }
                }
              },
            ),
          ),
          const Text(
            'Notificações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: notification.isRead
              ? colorScheme.outline
              : colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!notification.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .markAsRead(notification.id);
                        _navigateFromNotification(context, notification);
                      },
                      child: const Text(
                        'ver detalhes',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary),
            ),
            child: const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  void _navigateFromNotification(
    BuildContext context,
    AppNotification notification,
  ) {
    final tipo = notification.tipo;
    final payload = notification.payload ?? {};
    final codigoPublico = payload['codigo_publico'] as String?;
    final checkoutUrl = payload['checkout_url'] as String?;

    switch (tipo) {
      case 'APROVACAO_RESERVA':
      case 'PAGAMENTO_CONFIRMADO':
        if (checkoutUrl != null) {
          launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
        } else if (codigoPublico != null) {
          context.push('/tickets/details/$codigoPublico');
        }
      case 'RESERVA_CANCELADA':
        if (codigoPublico != null) {
          context.push('/tickets/details/$codigoPublico');
        }
      case 'NOVA_RESERVA':
        if (codigoPublico != null) {
          context.push('/tickets/details/$codigoPublico');
        } else {
          context.push('/tickets');
        }
      case 'MENSAGEM_CHAT':
        context.go('/chat');
      default:
        break;
    }
  }

  Widget _buildClearButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => ref.read(notificationsProvider.notifier).clearAll(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Text(
          'limpar',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 64, color: AppColors.secondary),
            const SizedBox(height: 20),
            Text(
              'Acesse suas notificações',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Faça login para receber atualizações sobre suas reservas e mensagens.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/auth/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ENTRAR AGORA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Sem novas notificações',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
