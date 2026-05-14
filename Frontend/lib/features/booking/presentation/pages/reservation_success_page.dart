import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';

/// Tela de confirmação mostrada após o pagamento. Duas variantes:
///
///   mode=user  → "Reserva confirmada! Veja seus tickets" com botão para /tickets
///   mode=guest → "Enviamos o ticket para seu email" com link pra /reservas/:codigo
class ReservationSuccessPage extends StatelessWidget {
  final String codigoPublico;
  final String mode; // 'user' | 'guest'

  const ReservationSuccessPage({
    super.key,
    required this.codigoPublico,
    this.mode = 'user',
  });

  bool get _isGuest => mode == 'guest';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: ContentMaxWidth.form,
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.successColor, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                'Reserva confirmada!',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isGuest
                    ? 'Enviamos o ticket da sua reserva para o email cadastrado. '
                      'Você também pode acessá-lo pelo link abaixo.'
                    : 'Sua reserva foi aprovada. Consulte os detalhes na aba Tickets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Código: ',
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                    ),
                    Flexible(
                      child: SelectableText(
                        codigoPublico,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
                      tooltip: 'Copiar',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: codigoPublico));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Código copiado'),
                            backgroundColor: colorScheme.inverseSurface,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isGuest) {
                      context.go('/reservas/$codigoPublico');
                    } else {
                      context.go('/tickets');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isGuest ? 'Ver meu ticket' : 'Ir para meus tickets',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Voltar à home', style: TextStyle(color: colorScheme.onSurface)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
