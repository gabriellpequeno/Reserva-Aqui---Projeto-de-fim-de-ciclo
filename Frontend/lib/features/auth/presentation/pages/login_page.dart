import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/auth_response.dart';
import '../widgets/auth_text_field.dart';

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
      late AuthResponse response;

      if (_role == 'host') {
        response = await authService.loginHotel(
          _emailController.text,
          _senhaController.text,
        );
      } else {
        try {
          response = await authService.loginGuest(
            _emailController.text,
            _senhaController.text,
          );
        } catch (e) {
          // Como o router pode mandar para cá sem a role definida (extra nulo),
          // tentamos fazer o login como anfitrião caso as credenciais não existam para hóspede.
          if (e is DioException && e.response?.statusCode == 401) {
            response = await authService.loginHotel(
              _emailController.text,
              _senhaController.text,
            );
            _role =
                'host'; // Atualiza a role para salvar corretamente no storage
          } else {
            rethrow;
          }
        }
      }

      final AuthRole role;
      if (_role == 'host') {
        role = AuthRole.host;
      } else if (response.papel == 'admin') {
        role = AuthRole.admin;
      } else {
        role = AuthRole.guest;
      }

      await ref
          .read(authProvider.notifier)
          .setAuth(response.accessToken, response.refreshToken, role);

      if (mounted) {
        context.go(role == AuthRole.admin ? '/profile/admin' : '/home');
      }
    } catch (e, stack) {
      if (!mounted) return;

      String message = 'Erro ao realizar login. Tente novamente.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          message = 'E-mail ou senha incorretos.';
        } else if (e.response?.statusCode == 429) {
          message = 'Muitas tentativas. Aguarde alguns minutos.';
        } else {
          message = 'Erro de conexão: ${e.message}';
        }
      } else {
        message = 'ERRO INESPERADO: $e';
        print('STACK TRACE: $stack');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
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
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
                    if (value == null || value.isEmpty)
                      return 'Informe o e-mail';
                    final emailRegex = RegExp(
                      r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                    );
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
                    if (value == null || value.isEmpty)
                      return 'Informe a senha';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(text: 'Login', onPressed: _submit),
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
