import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          'A Política de Privacidade do ReservAqui será publicada em breve. '
          'Seus dados são tratados com segurança e nunca compartilhados com terceiros '
          'sem seu consentimento. Entre em contato pelo suporte para mais informações.',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
