import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/date_picker_field.dart';
import '../../../../core/widgets/phone_mask_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/register_request.dart';
import '../../data/services/auth_service.dart';
import '../../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/terms_modal.dart';

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
  final _dataNascimentoController = TextEditingController();
  bool _isLoading = false;
  bool _termsAccepted = false;
  String? _termsError;
  late final TapGestureRecognizer _termsRecognizer;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => showTermsModal(context);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmController.dispose();
    _dataNascimentoController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  String? _validateSenha(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    final erros = <String>[];
    if (value.length < 8) erros.add('mínimo de 8 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(value)) erros.add('uma letra maiúscula');
    if (!RegExp(r'[a-z]').hasMatch(value)) erros.add('uma letra minúscula');
    if (!RegExp(r'[0-9]').hasMatch(value)) erros.add('um número');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) erros.add('um caractere especial');
    if (erros.isEmpty) return null;
    return 'A senha precisa ter:\n${erros.map((e) => '• $e').join('\n')}';
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

    final birthDate = DateTime(year, month, day);
    if (birthDate.day != day || birthDate.month != month) return 'Data inválida';

    final today = DateTime.now();
    final minBirthDate = DateTime(today.year - 18, today.month, today.day);
    if (birthDate.isAfter(minBirthDate)) {
      return 'Você deve ter pelo menos 18 anos para se cadastrar';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      setState(() => _termsError = 'Você deve aceitar os Termos e Condições para continuar');
      return;
    }

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
      final msg = switch (status) {
        409 => 'Este e-mail já está cadastrado.',
        400 => 'Dados inválidos. Verifique os campos e tente novamente.',
        _ => 'Erro no servidor. Tente novamente mais tarde.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final lastDateBirth = DateTime(today.year - 18, today.month, today.day);

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
                  'Cadastre-se',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  hintText: 'Nome Completo',
                  label: 'Nome Completo',
                  icon: Icons.person_outline,
                  maxLength: 100,
                  controller: _nomeController,
                  validator: validateNomeCompleto,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: '000.000.000-00',
                  label: 'CPF',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  controller: _cpfController,
                  inputFormatters: [_cpfFormatter],
                  validator: validateCpf,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: '(xx) xxxxx-xxxx',
                  label: 'Celular',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  controller: _telefoneController,
                  inputFormatters: [PhoneMaskFormatter()],
                  validator: validateTelefoneBr,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'email@domain.com',
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 254,
                  controller: _emailController,
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                DatePickerField(
                  controller: _dataNascimentoController,
                  validator: _validateData,
                  lastDate: lastDateBirth,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'Senha',
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  maxLength: 128,
                  controller: _senhaController,
                  validator: _validateSenha,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'Confirmar Senha',
                  label: 'Confirmar Senha',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  maxLength: 128,
                  controller: _confirmController,
                  validator: (value) {
                    if (value != _senhaController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.secondary,
                      onChanged: (v) => setState(() {
                        _termsAccepted = v ?? false;
                        _termsError = null;
                      }),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Eu concordo com os ',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Termos e Condições',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsRecognizer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
                    child: Text(
                      _termsError!,
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Cadastrar',
                        onPressed: _submit,
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
