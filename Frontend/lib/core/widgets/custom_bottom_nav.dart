import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Ordem das abas conforme navbar.png ───────────────────────
// 0: buscar | 1: curtidas | 2: início | 3: mensagens | 4: perfil

// Constantes de geometria — edite aqui para calibrar o visual
const double _kBarTopY      = 22.5; // onde a barra começa (espaço para a bolha)
const double _kBubbleSize   = 46.0; // diâmetro do círculo ativo
const double _kWidgetHeight = 99.5; // altura total do widget (barra + overflow bolha)

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.search,              Icons.search,              'buscar'),
    _NavItem(Icons.favorite_border,     Icons.favorite,            'curtidas'),
    _NavItem(Icons.home_outlined,       Icons.home,                'início'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble,         'mensagens'),
    _NavItem(Icons.person_outline,      Icons.person,              'perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildNav(constraints.maxWidth),
    );
  }

  Widget _buildNav(double navWidth) {
    final itemWidth = navWidth / _items.length;

    return SizedBox(
      width: navWidth,
      height: _kWidgetHeight,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        tween: Tween<double>(end: currentIndex.toDouble()),
        builder: (context, animatedIndex, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 1. Fundo com notch — segue animatedIndex ──────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _NavBarPainter(animatedIndex: animatedIndex),
                ),
              ),

              // ── 2. Bolha — se move horizontalmente com o notch ────
              // centerX da bolha = mesma fórmula do painter
              Positioned(
                top: _kBarTopY - _kBubbleSize / 2,
                left: itemWidth * animatedIndex + (itemWidth - _kBubbleSize) / 2,
                child: Container(
                  width: _kBubbleSize,
                  height: _kBubbleSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  // Ícone dentro da bolha: interpolado entre os dois ícones
                  child: _BubbleIcon(
                    animatedIndex: animatedIndex,
                    currentIndex: currentIndex,
                    items: _items,
                  ),
                ),
              ),

              // ── 3. Ícones estáticos na barra ──────────────────────
              Positioned.fill(
                child: Row(
                  children: List.generate(_items.length, (index) {
                    // Proximidade 0.0 (longe) → 1.0 (exatamente sob a bolha)
                    final double proximity =
                        (1.0 - (animatedIndex - index).abs()).clamp(0.0, 1.0);

                    return GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: itemWidth,
                        height: _kWidgetHeight,
                        child: _BarItem(
                          item: _items[index],
                          proximity: proximity,
                          isSelected: currentIndex == index,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Ícone dentro da bolha em movimento ───────────────────────
// Quando a bolha está entre dois itens, exibe o ícone do destino
// já com opacidade crescente (ou o de origem saindo).
class _BubbleIcon extends StatelessWidget {
  final double animatedIndex;
  final int currentIndex;
  final List<_NavItem> items;

  const _BubbleIcon({
    required this.animatedIndex,
    required this.currentIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // O ícone exibido na bolha é sempre o do destino (currentIndex).
    // A opacidade aparece conforme a bolha chega nele.
    final double arrivalProgress =
        (1.0 - (animatedIndex - currentIndex).abs()).clamp(0.0, 1.0);

    return Center(
      child: Icon(
        items[currentIndex].activeIcon,
        color: AppColors.secondary,
        // Tamanho: cresce de 18 → 24 conforme chega no destino
        size: 18 + 6 * arrivalProgress,
      ),
    );
  }
}

// ─── Item na barra (ícone + label) ────────────────────────────
class _BarItem extends StatelessWidget {
  final _NavItem item;
  final double proximity; // 0.0 = longe, 1.0 = bolha está aqui
  final bool isSelected;

  const _BarItem({
    required this.item,
    required this.proximity,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Quando a bolha está passando por cima deste item, o ícone da barra
    // some (opacity 0) — quem mostra o ícone é a própria bolha.
    // Quando a bolha se afasta, o ícone da barra aparece de volta.
    final double iconOpacity = isSelected
        ? 0.0 // o ativo não tem ícone na barra — só na bolha
        : (1.0 - proximity * 0.85).clamp(0.15, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: _kBarTopY),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone inativo — esmaece conforme a bolha passa por cima
              Opacity(
                opacity: iconOpacity,
                child: Icon(
                  item.icon,
                  color: Colors.white.withValues(alpha: 0.80),
                  size: 22,
                ),
              ),

              // Label: só visível no item realmente selecionado
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Stack Sans Headline',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Modelo de item ───────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─── Painter: fundo azul com notch suave ──────────────────────
class _NavBarPainter extends CustomPainter {
  final double animatedIndex;
  const _NavBarPainter({required this.animatedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final double itemWidth = size.width / 5;
    final double cx        = itemWidth * animatedIndex + itemWidth / 2;

    // depth = raio exato da bolha → notch encontra o fundo da bolha perfeitamente
    const double topY  = _kBarTopY;
    const double halfW = 50.0;
    const double depth = _kBubbleSize / 2; // 23 — igual ao raio da bolha

    final path = Path()
      ..moveTo(0, topY)
      ..lineTo(cx - halfW, topY);

    // ── DESCIDA ESQUERDA — dois segmentos G1-contínuos ────────
    // Um único cúbico com tangentes horizontais nos dois extremos
    // gera inevitavelmente um formato S (inflexão no meio = dureza).
    // Dois segmentos com junção G1 distribuem a curvatura de forma
    // uniforme, imitando um arco de círculo sem inflexão visível.

    // Segmento 1 — ombro → ponto médio do arco
    path.cubicTo(
      cx - halfW * 0.82, topY + depth * 0.01,  // CP1: sai quase horizontal
      cx - halfW * 0.46, topY + depth * 0.60,  // CP2: puxa para o meio do arco
      cx - halfW * 0.24, topY + depth * 0.86,  // EP: ponto de junção G1
    );
    // Segmento 2 — ponto médio do arco → fundo do vale
    // CP1 calculado para coincidir com a tangente de chegada do seg 1,
    // garantindo continuidade suave (sem quina perceptível).
    path.cubicTo(
      cx - halfW * 0.155, topY + depth * 0.961, // CP1: alinhado com tangente do seg 1
      cx - halfW * 0.02,  topY + depth,          // CP2: chega horizontalmente ao vale
      cx,                 topY + depth,           // EP: fundo do vale
    );

    // ── SUBIDA DIREITA — espelho exato da descida ─────────────
    path.cubicTo(
      cx + halfW * 0.02,  topY + depth,           // CP1: parte horizontal do vale
      cx + halfW * 0.155, topY + depth * 0.961,   // CP2
      cx + halfW * 0.24,  topY + depth * 0.86,    // EP: ponto de junção G1
    );
    path.cubicTo(
      cx + halfW * 0.46,  topY + depth * 0.60,    // CP1: alinhado com tangente do seg 1
      cx + halfW * 0.82,  topY + depth * 0.01,    // CP2: aproxima-se horizontal
      cx + halfW,         topY,                    // EP: ombro direito
    );

    path
      ..lineTo(size.width, topY)
      ..lineTo(size.width, size.height)
      ..lineTo(0,          size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter old) =>
      old.animatedIndex != animatedIndex;
}
