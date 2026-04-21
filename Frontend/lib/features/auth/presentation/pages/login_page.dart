import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                'Acesse agora',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              const AuthTextField(
                hintText: 'email@domain.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const AuthTextField(
                hintText: 'senha',
                isPassword: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Login',
                onPressed: () {
                  // Mock login and redirect to home
                  context.go('/home');
                },
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 32),
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
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'cadastre-se agora',
                color: AppColors.primary,
                textColor: Colors.white,
                onPressed: () {
                  context.go('/auth');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
