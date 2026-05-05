import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';


class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: tablet ? 520 : 420),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/images/home_page.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.75),
              AppColors.primary.withValues(alpha: 0.55),
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: tablet ? 80 : 60,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Encontre sua estadia perfeita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tablet ? 48 : 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reserve quartos únicos, de forma simples e rápida.\nO conforto que você merece está a um toque de distância.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: tablet ? 18 : 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => context.go('/search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Explorar quartos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
