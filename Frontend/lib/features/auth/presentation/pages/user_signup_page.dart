import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
  final _dataController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _dataFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _dataController.dispose();
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
      nomeCompleto: _nomeController.text.trim(),
      cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      dataNascimento: _dataController.text.trim(),
      numeroCelular: _telefoneController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    try {
      final service = ref.read(authServiceProvider);

      await service.register(request);
      final response = await service.login(request.email, request.senha);

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
                  hintText: 'CPF',
                  keyboardType: TextInputType.number,
                  controller: _cpfController,
                  inputFormatters: [_cpfFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CPF';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 11) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'dd/mm/aaaa',
                  keyboardType: TextInputType.datetime,
                  controller: _dataController,
                  inputFormatters: [_dataFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a data de nascimento';
                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                      return 'Formato inválido. Use dd/mm/aaaa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: '(11) 99999-9999',
                  keyboardType: TextInputType.phone,
                  controller: _telefoneController,
                  inputFormatters: [_telefoneFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o telefone';
                    if (!RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$').hasMatch(value)) {
                      return 'Formato inválido. Use (xx) xxxxx-xxxx';
                    }
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
                    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'A senha deve ter pelo menos uma letra maiúscula';
                    if (!RegExp(r'[a-z]').hasMatch(value)) return 'A senha deve ter pelo menos uma letra minúscula';
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_]').hasMatch(value)) return 'A senha deve conter um caractere especial';
                    if (!RegExp(r'[0-9]').hasMatch(value)) return 'A senha deve conter pelo menos um número';
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
