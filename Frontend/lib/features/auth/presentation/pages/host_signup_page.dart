import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/phone_mask_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/register_host_request.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cep_service.dart';
import '../widgets/auth_text_field.dart';

class HostSignUpPage extends ConsumerStatefulWidget {
  const HostSignUpPage({super.key});

  @override
  ConsumerState<HostSignUpPage> createState() => _HostSignUpPageState();
}

class _HostSignUpPageState extends ConsumerState<HostSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCepLoading = false;

  // Controllers
  final _nomeHotelController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _bairroController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();

  String? _selectedUf;

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  void _onCepChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return;

    setState(() => _isCepLoading = true);

    ref.read(cepServiceProvider).lookup(digits).then((result) {
      if (!mounted) return;
      if (result.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CEP não encontrado. Verifique e preencha manualmente.')),
        );
      } else {
        setState(() {
          _ruaController.text = result.logradouro ?? '';
          _bairroController.text = result.bairro ?? '';
          _cidadeController.text = result.localidade ?? '';
          if (result.uf != null && _estados.contains(result.uf)) {
            _selectedUf = result.uf;
          }
        });
      }
    }).catchError((_) {
      // Silent error as per plan
    }).whenComplete(() {
      if (mounted) {
        setState(() => _isCepLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _nomeHotelController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _descricaoController.dispose();
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o estado (UF)')),
      );
      return;
    }

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
      // Step 1: registrar hotel
      await ref.read(authServiceProvider).registerHotel(request);

      // Step 2: auto-login para obter tokens
      final authResponse = await ref.read(authServiceProvider).loginHotel(email, senha);

      // Step 3: persistir sessão com role host
      await ref.read(authProvider.notifier).setAuth(
            authResponse.accessToken,
            authResponse.refreshToken,
            AuthRole.host,
          );

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final msg = switch (status) {
        409 => 'Este CNPJ ou e-mail já está cadastrado.',
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
                const SizedBox(height: 80),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CNPJ';
                    if (!RegExp(r'^[\d\.\-\/]+$').hasMatch(value)) return 'CNPJ inválido';
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
                    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'cep',
                  keyboardType: TextInputType.number,
                  controller: _cepController,
                  onChanged: _onCepChanged,
                  suffixIcon: _isCepLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o CEP';
                    if (!RegExp(r'^[\d\-]+$').hasMatch(value)) return 'CEP inválido';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 8) return 'CEP inválido (8 dígitos)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUf,
                        isExpanded: true,
                        hint: const Text('UF', style: TextStyle(color: AppColors.greyText, fontSize: 14)),
                        items: _estados.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedUf = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.strokeLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.strokeLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.strokeLight),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) => value == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  hintText: 'bairro',
                  controller: _bairroController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe o bairro';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'complemento',
                  controller: _complementoController,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  hintText: 'descrição do hotel',
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
                  controller: _confirmSenhaController,
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
    );
  }
}
