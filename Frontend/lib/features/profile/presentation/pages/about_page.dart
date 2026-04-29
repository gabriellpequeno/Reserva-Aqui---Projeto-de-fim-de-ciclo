import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o App'),
        foregroundColor: AppColors.primary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReservAqui',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Versão 1.0.0',
              style: TextStyle(fontSize: 14, color: AppColors.greyText),
            ),
            SizedBox(height: 24),
            Text(
              'O ReservAqui é uma plataforma de gestão inteligente de reservas hoteleiras, '
              'conectando hóspedes e anfitriões de forma simples e eficiente.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
