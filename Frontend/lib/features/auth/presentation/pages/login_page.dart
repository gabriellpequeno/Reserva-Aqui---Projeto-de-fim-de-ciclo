import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/auth_response.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  late String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _role = extra?['role'] as String? ?? 'guest';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final AuthResponse response;

      if (_role == 'host') {
        response = await authService.loginHotel(
          _emailController.text,
          _senhaController.text,
        );
      } else {
        response = await authService.loginGuest(
          _emailController.text,
          _senhaController.text,
        );
      }

      final role = _role == 'host' ? AuthRole.host : AuthRole.guest;
      await ref.read(authProvider.notifier).setAuth(
            response.accessToken,
            response.refreshToken,
            role,
          );

      if (mounted) {
        context.go('/home');
      }
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Erro ao realizar login. Tente novamente.';
      if (e.response?.statusCode == 401) {
        message = 'E-mail ou senha incorretos.';
      } else if (e.response?.statusCode == 429) {
        message = 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Text(
                  _role == 'host' ? 'Acesso Anfitrião' : 'Acesse agora',
                  style: const TextStyle(
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
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o e-mail';
                    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _senhaController,
                  hintText: 'senha',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a senha';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Login',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'cadastre-se agora',
                  color: AppColors.primary,
                  textColor: Colors.white,
                  onPressed: () {
                    context.push('/auth');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
