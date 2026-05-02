import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class UserOrHostPage extends StatelessWidget {
  const UserOrHostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
                  Expanded(child: Divider(color: colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Ou',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Sou Anfitrião',
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                onPressed: () => context.push('/auth/signup/host'),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => context.pop(),
                child: RichText(
                  text: TextSpan(
                    text: 'Já tem conta? ',
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                    children: const [
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
