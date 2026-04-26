import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(authServiceProvider);

      // Try user login first
      try {
        final response = await service.login(email, senha);
        await ref.read(authProvider.notifier).setAuth(
              response.accessToken,
              response.refreshToken,
              AuthRole.guest,
            );
        if (mounted) context.go('/home');
        return;
      } catch (userError) {
        // If user login fails, try hotel login
        try {
          final response = await service.loginHotel(email, senha);
          await ref.read(authProvider.notifier).setAuth(
                response.accessToken,
                response.refreshToken,
                AuthRole.host,
              );
          if (mounted) context.go('/home');
          return;
        } catch (hotelError) {
          if (mounted) {
            String errorMsg = 'Credenciais inválidas';
            if (hotelError is DioException && hotelError.response?.statusCode == 404) {
               errorMsg = 'Usuário não encontrado';
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              AuthTextField(
                controller: _emailController,
                hintText: 'email@domain.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _senhaController,
                hintText: 'senha',
                isPassword: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Login',
                      onPressed: _submit,
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
