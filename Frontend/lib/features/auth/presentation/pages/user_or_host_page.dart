import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class UserOrHostPage extends StatelessWidget {
  const UserOrHostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Sou Hóspede',
                onPressed: () => context.push('/auth/signup/user'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.strokeLight)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Ou',
                      style: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.strokeLight)),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Sou Anfitrião',
                color: AppColors.primary,
                textColor: Colors.white,
                onPressed: () => context.push('/auth/signup/host'),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => context.pop(),
                child: RichText(
                  text: const TextSpan(
                    text: 'Já tem conta? ',
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                    children: [
                      TextSpan(
                        text: 'acesse agora',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
