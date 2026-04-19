import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/auth_text_field.dart';

class HostSignUpPage extends StatelessWidget {
  const HostSignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),
              const Text(
                'cadastre seu hotel',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const AuthTextField(hintText: 'nome hotel'),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'cnpj', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'Telefone', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'email@domain.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'cep', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(flex: 3, child: AuthTextField(hintText: 'cidade')),
                  const SizedBox(width: 8),
                  const Expanded(flex: 1, child: AuthTextField(hintText: 'uf')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(flex: 3, child: AuthTextField(hintText: 'Rua')),
                  const SizedBox(width: 8),
                  const Expanded(flex: 1, child: AuthTextField(hintText: 'n°')),
                ],
              ),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'complemento'),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'bairro'),
              const SizedBox(height: 16),
              const AuthTextField(
                hintText: 'descrição do hotel (até 100 palavras)',
                // In a real app we might want a multiline field here
              ),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'senha', isPassword: true),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'confirmar senha', isPassword: true),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Cadastrar Hotel',
                onPressed: () {
                  // Mock signup
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
