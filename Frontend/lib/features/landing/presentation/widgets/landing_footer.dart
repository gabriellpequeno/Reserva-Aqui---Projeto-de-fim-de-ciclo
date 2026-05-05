import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/breakpoints.dart';
import 'landing_theme_bg.dart';

class LandingFooter extends StatelessWidget {
  final VoidCallback? onHeroTap;
  final VoidCallback? onHowItWorksTap;
  final VoidCallback? onRoomsTap;
  final VoidCallback? onBeneTap;
  final VoidCallback? onTestimonialsTap;

  const LandingFooter({
    super.key,
    this.onHeroTap,
    this.onHowItWorksTap,
    this.onRoomsTap,
    this.onBeneTap,
    this.onTestimonialsTap,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);

    return LandingThemedBox(
      child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: tablet ? 48 : 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              if (tablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _BrandColumn()),
                    const SizedBox(width: 40),
                    Expanded(child: _LinksColumn(
                      title: 'Navegar',
                      links: _sectionLinks(context),
                    )),
                    const SizedBox(width: 40),
                    Expanded(child: _LinksColumn(
                      title: 'Empresa',
                      links: _companyLinks,
                    )),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BrandColumn(),
                    const SizedBox(height: 28),
                    _LinksColumn(
                      title: 'Navegar',
                      links: _sectionLinks(context),
                    ),
                    const SizedBox(height: 28),
                    _LinksColumn(
                      title: 'Empresa',
                      links: _companyLinks,
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 26,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.45),
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '© ${DateTime.now().year} Reserva Aqui. Todos os direitos reservados.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  List<_LinkItem> _sectionLinks(BuildContext context) => [
    _LinkItem('Início', onHeroTap),
    _LinkItem('Como Funciona', onHowItWorksTap),
    _LinkItem('Quartos em Destaque', onRoomsTap),
    _LinkItem('Bene — IA', onBeneTap),
    _LinkItem('Depoimentos', onTestimonialsTap),
  ];

  static const _companyLinks = [
    _LinkItem('Sobre nós', null),
    _LinkItem('Contato', null),
  ];
}

class _LinkItem {
  final String label;
  final VoidCallback? onTap;
  const _LinkItem(this.label, this.onTap);
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reserva Aqui',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reserve com conforto.\nViva experiências únicas.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _LinksColumn extends StatelessWidget {
  final String title;
  final List<_LinkItem> links;
  const _LinksColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: link.onTap,
                child: Text(
                  link.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
