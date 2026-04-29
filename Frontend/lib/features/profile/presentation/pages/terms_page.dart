import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        foregroundColor: AppColors.primary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          'Os Termos de Uso do ReservAqui serão publicados em breve. '
          'Ao utilizar o aplicativo, você concorda com nossas políticas de uso, '
          'privacidade e conduta. Entre em contato pelo suporte para mais informações.',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
