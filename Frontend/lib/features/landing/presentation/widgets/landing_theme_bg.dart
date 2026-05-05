import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Fundo temático compartilhado pelo header, seção Bene e footer.
/// Gradiente navy profundo + grade de pontos + arcos decorativos de IA.
class LandingThemedBox extends StatelessWidget {
  final Widget child;

  const LandingThemedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B35),
            Color(0xFF182541),
            Color(0xFF1E3A5F),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _BgCanvas()),
          child,
        ],
      ),
    );
  }
}

class _BgCanvas extends StatelessWidget {
  const _BgCanvas();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BgPainter());
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dot grid
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Decorative arcs — bottom-left corner
    final arcPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.85),
        size.width * 0.14 * i,
        arcPaint,
      );
    }

    // Decorative arcs — top-right corner
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.95, size.height * 0.15),
        size.width * 0.11 * i,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter _) => false;
}
