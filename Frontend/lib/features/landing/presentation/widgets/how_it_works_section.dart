import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';

class HowItWorksSection extends StatefulWidget {
  final ValueNotifier<bool> revealed;
  const HowItWorksSection({super.key, required this.revealed});

  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection>
    with TickerProviderStateMixin {
  // Semicircle slide-in
  late final AnimationController _leftCtrl;
  late final AnimationController _rightCtrl;
  late final Animation<double> _leftAnim;
  late final Animation<double> _rightAnim;

  // Per-step staggered reveal
  static const int _stepCount = 4;
  late final List<AnimationController> _leftStepCtrl;
  late final List<AnimationController> _rightStepCtrl;
  late final List<Animation<double>> _leftStepAnim;
  late final List<Animation<double>> _rightStepAnim;

  @override
  void initState() {
    super.initState();

    _leftCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _rightCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _leftAnim =
        CurvedAnimation(parent: _leftCtrl, curve: Curves.easeOutCubic);
    _rightAnim =
        CurvedAnimation(parent: _rightCtrl, curve: Curves.easeOutCubic);

    _leftStepCtrl = List.generate(
      _stepCount,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 520)),
    );
    _rightStepCtrl = List.generate(
      _stepCount,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 520)),
    );

    const stepCurve = Curves.easeOutCubic;
    _leftStepAnim = _leftStepCtrl
        .map((c) => CurvedAnimation(parent: c, curve: stepCurve))
        .toList();
    _rightStepAnim = _rightStepCtrl
        .map((c) => CurvedAnimation(parent: c, curve: stepCurve))
        .toList();

    widget.revealed.addListener(_onReveal);
    if (widget.revealed.value) _onReveal();
  }

  void _onReveal() {
    if (!widget.revealed.value) return;
    _leftCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _rightCtrl.forward();
    });
    for (int i = 0; i < _stepCount; i++) {
      Future.delayed(Duration(milliseconds: 350 + i * 200), () {
        if (mounted) _leftStepCtrl[i].forward();
      });
      Future.delayed(Duration(milliseconds: 500 + i * 200), () {
        if (mounted) _rightStepCtrl[i].forward();
      });
    }
  }

  @override
  void dispose() {
    widget.revealed.removeListener(_onReveal);
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    for (final c in [..._leftStepCtrl, ..._rightStepCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  static const double _diameter = 480.0;
  static const double _radius = _diameter / 2;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);

    return ClipRect(
      child: Stack(
        children: [
          // ── Left semicircle ──────────────────────────────────────
          if (tablet)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _leftAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(-_radius * (1 - _leftAnim.value), 0),
                      child: Opacity(opacity: _leftAnim.value, child: child),
                    ),
                    child: _SemiCircleImage(
                      imageAsset: 'lib/assets/images/landing_page.jpg',
                      fromLeft: true,
                      accentColor: AppColors.secondary,
                      diameter: _diameter,
                    ),
                  ),
                ),
              ),
            ),

          // ── Right semicircle ─────────────────────────────────────
          if (tablet)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _rightAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_radius * (1 - _rightAnim.value), 0),
                      child: Opacity(opacity: _rightAnim.value, child: child),
                    ),
                    child: _SemiCircleImage(
                      imageAsset: 'lib/assets/images/home_page.jpeg',
                      fromLeft: false,
                      accentColor: AppColors.primary,
                      diameter: _diameter,
                    ),
                  ),
                ),
              ),
            ),

          // ── Content ──────────────────────────────────────────────
          Container(
            color: AppColors.bgSecondary,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? _radius + 48 : 32,
              vertical: tablet ? 100 : 60, // taller for visual effect
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Logo as section title
                    SvgPicture.asset(
                      'lib/assets/icons/logo/logo.svg',
                      height: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Como Funciona',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        fontSize: 13,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 64),
                    if (tablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _AnimatedFlowColumn(
                              title: 'Para Hóspedes',
                              steps: _guestSteps,
                              stepAnimations: _leftStepAnim,
                              isRight: false,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _AnimatedFlowColumn(
                              title: 'Para Anfitriões',
                              steps: _hostSteps,
                              stepAnimations: _rightStepAnim,
                              isRight: true,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _AnimatedFlowColumn(
                            title: 'Para Hóspedes',
                            steps: _guestSteps,
                            stepAnimations: _leftStepAnim,
                            isRight: false,
                          ),
                          const SizedBox(height: 48),
                          _AnimatedFlowColumn(
                            title: 'Para Anfitriões',
                            steps: _hostSteps,
                            stepAnimations: _rightStepAnim,
                            isRight: true,
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _guestSteps = [
    _Step(Icons.search, 'Buscar',
        'Pesquise por destino, data e número de hóspedes.'),
    _Step(Icons.bed, 'Escolher',
        'Veja fotos, comodidades e avaliações do quarto ideal.'),
    _Step(Icons.credit_card, 'Reservar',
        'Confirme a reserva de forma rápida e segura.'),
    _Step(Icons.check_circle_outline, 'Check-in',
        'Chegue tranquilo — tudo já estará pronto para você.'),
  ];

  static const _hostSteps = [
    _Step(Icons.apartment, 'Cadastrar Hotel',
        'Crie seu perfil de anfitrião e cadastre seu espaço.'),
    _Step(Icons.visibility, 'Ganhar Visibilidade',
        'Seu espaço é exibido para milhares de hóspedes.'),
    _Step(Icons.bar_chart, 'Acompanhar Métricas',
        'Monitore reservas, avaliações e desempenho no dashboard.'),
    _Step(Icons.star, 'Crescer',
        'Fidelize hóspedes e aumente sua renda com o Reserva Aqui.'),
  ];
}

// ── Animated flow column ───────────────────────────────────────

class _AnimatedFlowColumn extends StatelessWidget {
  final String title;
  final List<_Step> steps;
  final List<Animation<double>> stepAnimations;
  final bool isRight;

  const _AnimatedFlowColumn({
    required this.title,
    required this.steps,
    required this.stepAnimations,
    required this.isRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 28),
        ...steps.asMap().entries.map(
          (e) => AnimatedBuilder(
            animation: stepAnimations[e.key],
            builder: (_, child) => Transform.translate(
              offset: Offset(
                isRight
                    ? 40 * (1 - stepAnimations[e.key].value)
                    : -40 * (1 - stepAnimations[e.key].value),
                0,
              ),
              child: Opacity(
                  opacity: stepAnimations[e.key].value, child: child),
            ),
            child: _StepTile(
              step: e.value,
              isLast: e.key == steps.length - 1,
              isRight: isRight,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final _Step step;
  final bool isLast;
  final bool isRight;

  const _StepTile({
    required this.step,
    required this.isLast,
    required this.isRight,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(step.icon, color: Colors.white, size: 22),
    );

    final connector = Container(
      width: 2,
      height: 40,
      color: AppColors.primary.withValues(alpha: 0.2),
    );

    final textBlock = Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isLast ? 0 : 20,
          left: isRight ? 0 : 16,
          right: isRight ? 16 : 0,
        ),
        child: Column(
          crossAxisAlignment:
              isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              textAlign: isRight ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.description,
              textAlign: isRight ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );

    final iconColumn = Column(
      children: [
        icon,
        if (!isLast) connector,
      ],
    );

    return isRight
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [textBlock, iconColumn],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [iconColumn, textBlock],
          );
  }
}

// ── Semicircle ─────────────────────────────────────────────────

class _SemiCircleImage extends StatelessWidget {
  final String imageAsset;
  final bool fromLeft;
  final Color accentColor;
  final double diameter;

  const _SemiCircleImage({
    required this.imageAsset,
    required this.fromLeft,
    required this.accentColor,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    final radius = diameter / 2;

    return SizedBox(
      width: radius,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ClipRect(
            child: Align(
              alignment: fromLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              widthFactor: 0.5,
              child: Stack(
                children: [
                  SizedBox(
                    width: diameter,
                    height: diameter,
                    child: ClipOval(
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: diameter,
                    height: diameter,
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.transparent,
                              accentColor.withValues(alpha: 0.28),
                            ],
                            radius: 0.85,
                            center: fromLeft
                                ? const Alignment(-0.5, 0)
                                : const Alignment(0.5, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: diameter,
                    height: diameter,
                    child: CustomPaint(
                      painter: _RingPainter(color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawCircle(
      Offset(r, r),
      r - 2,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(r, r),
      r - 8,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}

// ── Data ───────────────────────────────────────────────────────

class _Step {
  final IconData icon;
  final String title;
  final String description;
  const _Step(this.icon, this.title, this.description);
}
