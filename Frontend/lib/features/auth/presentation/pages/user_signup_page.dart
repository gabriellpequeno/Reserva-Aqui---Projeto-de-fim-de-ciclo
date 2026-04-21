import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_button.dart';

class UserSignUpPage extends StatelessWidget {
  const UserSignUpPage({super.key});

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
                'cadastre-se',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const AuthTextField(hintText: 'nome completo'),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'Cpf', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'Telefone', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'email@domain.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'senha', isPassword: true),
              const SizedBox(height: 16),
              const AuthTextField(hintText: 'confirmar senha', isPassword: true),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Cadastrar',
                onPressed: () {
                  // Mock signup
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.strokeLight)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'ou',
                      style: TextStyle(color: AppColors.greyText),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.strokeLight)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SocialButton(
                    text: 'Continue with Google',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  SocialButton(
                    text: 'Continue with Apple',
                    isApple: true,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/auth/signup/host'),
                  child: const Text(
                    'É um anfitrião? Cadastre seu hotel aqui',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
