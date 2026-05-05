import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/phone_mask_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/register_host_request.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class HostSignUpPage extends ConsumerStatefulWidget {
  const HostSignUpPage({super.key});

  @override
  ConsumerState<HostSignUpPage> createState() => _HostSignUpPageState();
}

class _HostSignUpPageState extends ConsumerState<HostSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeHotelController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  String? _selectedUf;
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeHotelController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _descricaoController.dispose();
    _senhaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final request = RegisterHostRequest(
      nomeHotel: _nomeHotelController.text.trim(),
      cnpj: _cnpjController.text.replaceAll(RegExp(r'\D'), ''),
      telefone: _telefoneController.text,
      email: email,
      senha: senha,
      cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
      uf: _selectedUf!,
      cidade: _cidadeController.text.trim(),
      bairro: _bairroController.text.trim(),
      rua: _ruaController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      descricao: _descricaoController.text.trim(),
    );

    try {
      final service = ref.read(authServiceProvider);

      await service.registerHotel(request);

      final response = await service.loginHotel(email, senha);

      await ref.read(authProvider.notifier).setAuth(
            response.accessToken,
            response.refreshToken,
            AuthRole.host,
          );

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final msg = switch (status) {
        409 => 'Este e-mail ou CNPJ já está cadastrado.',
        400 => 'Dados inválidos. Verifique os campos.',
        _ => 'Erro no servidor. Tente novamente mais tarde.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCepChanged(String value) async {
    final cep = value.replaceAll(RegExp(r'\D'), '');
    if (cep.length == 8) {
      try {
        final response = await Dio().get('https://viacep.com.br/ws/$cep/json/');
        if (response.data != null && response.data['erro'] == null) {
          setState(() {
            _cidadeController.text = response.data['localidade'] ?? '';
            _ufController.text = response.data['uf'] ?? '';
            _selectedUf = response.data['uf'];
            _ruaController.text = response.data['logradouro'] ?? '';
            _bairroController.text = response.data['bairro'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar CEP: $e');
      }
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
                  'cadastre seu hotel',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  hintText: 'nome hotel',
                  controller: _nomeHotelController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe o nome do hotel';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'cnpj',
                  keyboardType: TextInputType.number,
                  controller: _cnpjController,
                  inputFormatters: [_cnpjFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CNPJ';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 14) return 'CNPJ inválido (14 dígitos)';
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
                    if (!value.contains('@') || !value.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'cep',
                  keyboardType: TextInputType.number,
                  controller: _cepController,
                  inputFormatters: [_cepFormatter],
                  onChanged: _onCepChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CEP';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 8) return 'CEP inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AuthTextField(
                        hintText: 'cidade',
                        controller: _cidadeController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe a cidade';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.strokeLight),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUf,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'UF',
                            hintStyle: TextStyle(color: AppColors.greyText, fontSize: 16),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: AppColors.primary, fontSize: 16),
                          items: const [
                            'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA',
                            'MG','MS','MT','PA','PB','PE','PI','PR','RJ','RN',
                            'RO','RR','RS','SC','SE','SP','TO',
                          ].map((uf) => DropdownMenuItem(value: uf, child: Text(uf))).toList(),
                          onChanged: (uf) => setState(() {
                            _selectedUf = uf;
                            _ufController.text = uf ?? '';
                          }),
                          validator: (_) => _selectedUf == null ? 'UF' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AuthTextField(
                        hintText: 'Rua',
                        controller: _ruaController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe a rua';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: AuthTextField(
                        hintText: 'n°',
                        controller: _numeroController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'N°';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'complemento',
                  controller: _complementoController,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'bairro',
                  controller: _bairroController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe o bairro';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'descrição do hotel (até 100 palavras)',
                  controller: _descricaoController,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'senha',
                  isPassword: true,
                  controller: _senhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a senha';
                    final erros = <String>[];
                    if (!RegExp(r'[A-Z]').hasMatch(value)) erros.add('uma letra maiúscula');
                    if (!RegExp(r'[a-z]').hasMatch(value)) erros.add('uma letra minúscula');
                    if (!RegExp(r'[0-9]').hasMatch(value)) erros.add('um número');
                    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) erros.add('um caractere especial');
                    if (erros.isEmpty) return null;
                    return 'A senha precisa ter: ${erros.join(', ')}';
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
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Cadastrar Hotel',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 40),
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
