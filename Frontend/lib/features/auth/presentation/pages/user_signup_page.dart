import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/date_picker_field.dart';
import '../../../../core/widgets/phone_mask_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/register_request.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class UserSignUpPage extends ConsumerStatefulWidget {
  final VoidCallback? onHostSignupTap;

  const UserSignUpPage({super.key, this.onHostSignupTap});

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
  final _dataNascimentoController = TextEditingController();
  bool _isLoading = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  String? _validateSenha(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    final erros = <String>[];
    if (!RegExp(r'[A-Z]').hasMatch(value)) erros.add('uma letra maiúscula');
    if (!RegExp(r'[a-z]').hasMatch(value)) erros.add('uma letra minúscula');
    if (!RegExp(r'[0-9]').hasMatch(value)) erros.add('um número');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) erros.add('um caractere especial');
    if (erros.isEmpty) return null;
    return 'A senha precisa ter: ${erros.join(', ')}';
  }

  String? _validateData(String? value) {
    if (value == null || value.isEmpty) return 'Informe a data de nascimento';
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Use o formato dd/mm/aaaa';
    final parts = value.split('/');
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return 'Data inválida';
    if (month < 1 || month > 12) return 'Mês inválido';
    if (day < 1 || day > 31) return 'Dia inválido';
    if (year < 1900 || year > DateTime.now().year) return 'Ano inválido';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      nomeCompleto: _nomeController.text.trim(),
      cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      numeroCelular: _telefoneController.text,
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      dataNascimento: _dataNascimentoController.text,
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
      final serverMsg = (e.response?.data as Map?)?['error'] as String?;
      final msg = switch (status) {
        409 => 'Este e-mail já está cadastrado.',
        400 => serverMsg ?? 'Dados inválidos. Verifique os campos.',
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxFormWidth),
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
                    if (!RegExp(r'^[\d\.\-]+$').hasMatch(value)) return 'CPF inválido';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 11) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: '(xx) xxxxx-xxxx',
                  keyboardType: TextInputType.phone,
                  controller: _telefoneController,
                  inputFormatters: [PhoneMaskFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o telefone';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 11) return 'Telefone inválido (10 ou 11 dígitos com DDD)';
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
                    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DatePickerField(
                  controller: _dataNascimentoController,
                  validator: _validateData,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'senha',
                  isPassword: true,
                  controller: _senhaController,
                  validator: _validateSenha,
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
                Center(
                  child: TextButton(
                    onPressed: widget.onHostSignupTap ?? () => context.push('/auth/signup/host'),
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
        ),
      ),
    );
  }
}
