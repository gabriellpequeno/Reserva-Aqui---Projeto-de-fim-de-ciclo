import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../data/models/testimonial_model.dart';

final _featured = mockTestimonials.take(3).toList();

// Stagger the float phase per card so they never all move together
const _floatPhases = [0.0, 0.33, 0.66];
const _floatAmplitude = 10.0; // px up/down
const _floatDuration = Duration(milliseconds: 2800);

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);

    return Container(
      color: const Color(0xFFF0F4F8),
      padding: EdgeInsets.symmetric(vertical: tablet ? 80 : 52),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: 'O que dizem nossos ',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
              children: const [
                TextSpan(
                    text: 'Hóspedes',
                    style: TextStyle(color: AppColors.secondary))
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Experiências reais de quem já se hospedou com o Reserva Aqui.',
            style: TextStyle(color: AppColors.greyText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 52),
          if (tablet)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  _featured.length,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: i == 1 ? 0 : 24, // middle card taller
                      ),
                      child: _FloatingCard(
                        testimonial: _featured[i],
                        phaseOffset: _floatPhases[i],
                        accentColor: i == 1
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Column(
              children: List.generate(
                _featured.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _FloatingCard(
                    testimonial: _featured[i],
                    phaseOffset: _floatPhases[i],
                    accentColor: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ── Floating wrapper ───────────────────────────────────────────

class _FloatingCard extends StatefulWidget {
  final TestimonialModel testimonial;
  final double phaseOffset;
  final Color accentColor;

  const _FloatingCard({
    required this.testimonial,
    required this.phaseOffset,
    required this.accentColor,
  });

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _floatDuration)
      ..repeat(reverse: true);
    // Start at different phase so cards float independently
    _ctrl.forward(from: widget.phaseOffset);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, (_anim.value * 2 - 1) * _floatAmplitude),
        child: child,
      ),
      child: _CardContent(
        testimonial: widget.testimonial,
        accentColor: widget.accentColor,
      ),
    );
  }
}

// ── Card content ───────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final TestimonialModel testimonial;
  final Color accentColor;

  const _CardContent({
    required this.testimonial,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.14),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: accentColor.withValues(alpha: 0.12),
            child: Text(
              testimonial.userName.isNotEmpty
                  ? testimonial.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stars
          _StarRating(rating: testimonial.rating, color: accentColor),
          const SizedBox(height: 4),

          // Name
          Text(
            testimonial.userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          // Hotel
          if (testimonial.hotelName != null) ...[
            const SizedBox(height: 2),
            Text(
              testimonial.hotelName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.greyText, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 20),

          // Accent divider
          Container(
            width: 36,
            height: 2,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 20),

          // Review text
          Text(
            testimonial.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13.5,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final Color color;
  const _StarRating({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, color: color, size: 16);
        } else if (i < rating) {
          return Icon(Icons.star_half, color: color, size: 16);
        }
        return Icon(Icons.star_border, color: color, size: 16);
      }),
    );
  }
}
