import 'package:flutter/material.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Breakpoints.isDesktop(context) ? null : const CustomAppBar(),
      body: const ResponsiveCenter(
        maxWidth: ContentMaxWidth.reading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Text(
            'Os Termos de Uso do ReservAqui serão publicados em breve. '
            'Ao utilizar o aplicativo, você concorda com nossas políticas de uso, '
            'privacidade e conduta. Entre em contato pelo suporte para mais informações.',
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ),
    );
  }
}
