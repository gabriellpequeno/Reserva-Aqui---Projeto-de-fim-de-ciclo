import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E7A1E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF1E7A1E), size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reserva confirmada!',
                style: TextStyle(
                  color: AppColors.primary,
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
                style: const TextStyle(color: AppColors.primary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Código: ',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
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
                          const SnackBar(content: Text('Código copiado')),
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
                child: const Text('Voltar à home', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
