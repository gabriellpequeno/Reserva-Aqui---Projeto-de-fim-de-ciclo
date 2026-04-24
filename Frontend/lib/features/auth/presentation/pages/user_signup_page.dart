import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/register_request.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_button.dart';

class UserSignUpPage extends ConsumerStatefulWidget {
  const UserSignUpPage({super.key});

  @override
  ConsumerState<UserSignUpPage> createState() => _UserSignUpPageState();
}

class _UserSignUpPageState extends ConsumerState<UserSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      nome: _nomeController.text.trim(),
      cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      telefone: _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    try {
      final response = await ref.read(authServiceProvider).register(request);

      await ref.read(authProvider.notifier).setAuth(
            response.accessToken,
            response.refreshToken,
            AuthRole.guest,
          );

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final msg = switch (status) {
        409 => 'Este e-mail já está cadastrado.',
        400 => 'Dados inválidos. Verifique os campos.',
        _ => 'Erro no servidor. Tente novamente mais tarde.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          child: Form(
            key: _formKey,
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
                AuthTextField(
                  hintText: 'nome completo',
                  controller: _nomeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe seu nome';
                    if (value.trim().length < 3) return 'Nome muito curto';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'Cpf',
                  keyboardType: TextInputType.number,
                  controller: _cpfController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CPF';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 11) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'Telefone',
                  keyboardType: TextInputType.phone,
                  controller: _telefoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o telefone';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) return 'Telefone inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'email@domain.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o e-mail';
                    if (!value.contains('@') || !value.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'senha',
                  isPassword: true,
                  controller: _senhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a senha';
                    if (value.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'confirmar senha',
                  isPassword: true,
                  controller: _confirmController,
                  validator: (value) {
                    if (value != _senhaController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Cadastrar',
                        onPressed: _submit,
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
      ),
    );
  }
}
