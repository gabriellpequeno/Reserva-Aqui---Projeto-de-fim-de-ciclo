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

  final _nomeHotelController   = TextEditingController();
  final _cnpjController        = TextEditingController();
  final _telefoneController    = TextEditingController();
  final _emailController       = TextEditingController();
  final _cepController         = TextEditingController();
  final _cidadeController      = TextEditingController();
  final _ufController          = TextEditingController();
  final _ruaController         = TextEditingController();
  final _numeroController      = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController      = TextEditingController();
  final _descricaoController   = TextEditingController();
  final _senhaController       = TextEditingController();
  final _confirmController     = TextEditingController();

  String? _selectedUf;
  bool    _isLoading      = false;
  bool    _obscureSenha   = true;
  bool    _obscureConfirm = true;
  bool    _termsAccepted  = false;

  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
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

    if (!_termsAccepted) {
      _showSnack('Aceite os Termos e Condições para continuar.');
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final request = RegisterHostRequest(
      nomeHotel:   _nomeHotelController.text.trim(),
      cnpj:        _cnpjController.text.replaceAll(RegExp(r'\D'), ''),
      telefone:    _telefoneController.text,
      email:       email,
      senha:       senha,
      cep:         _cepController.text.replaceAll(RegExp(r'\D'), ''),
      uf:          _selectedUf!,
      cidade:      _cidadeController.text.trim(),
      bairro:      _bairroController.text.trim(),
      rua:         _ruaController.text.trim(),
      numero:      _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      descricao:   _descricaoController.text.trim(),
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
        _   => 'Erro no servidor. Tente novamente mais tarde.',
      };
      _showSnack(msg);
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
            _ufController.text     = response.data['uf'] ?? '';
            _selectedUf            = response.data['uf'];
            _ruaController.text    = response.data['logradouro'] ?? '';
            _bairroController.text = response.data['bairro'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar CEP: $e');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTermsModal() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Termos e Condições',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            '1. Uso da Plataforma\n'
            'O ReservAqui é uma plataforma de intermediação de reservas. '
            'O hotel é responsável pela precisão das informações cadastradas, '
            'incluindo disponibilidade, preços e políticas.\n\n'
            '2. Responsabilidades do Anfitrião\n'
            'O anfitrião deve manter os dados do estabelecimento atualizados '
            'e honrar as reservas confirmadas pela plataforma.\n\n'
            '3. Dados Pessoais\n'
            'As informações fornecidas serão utilizadas exclusivamente para '
            'fins operacionais da plataforma, conforme nossa Política de Privacidade.\n\n'
            '4. Cancelamentos\n'
            'A política de cancelamento é definida por cada estabelecimento '
            'e deve estar claramente informada no perfil do hotel.\n\n'
            '5. Alterações dos Termos\n'
            'O ReservAqui reserva-se o direito de atualizar estes termos a '
            'qualquer momento, notificando os usuários por e-mail.\n\n'
            'Dúvidas? Entre em contato: suporte@reservaqui.dev',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Campo de senha com toggle de visibilidade
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      validator:    validator,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.secondary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled:    true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        errorMaxLines: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: ContentMaxWidth.form,
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Text(
                  'Cadastre Seu Hotel',
                  style: TextStyle(
                    color:      colorScheme.onSurface,
                    fontSize:   24,
                    fontWeight: FontWeight.w700,
                    height:     1.2,
                  ),
                ),
                const SizedBox(height: 24),

                // Nome do hotel
                AuthTextField(
                  hintText: 'Nome do Hotel',
                  controller: _nomeHotelController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o Nome do Hotel';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNPJ
                AuthTextField(
                  hintText:        'CNPJ',
                  keyboardType:    TextInputType.number,
                  controller:      _cnpjController,
                  inputFormatters: [_cnpjFormatter],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o CNPJ';
                    if (v.replaceAll(RegExp(r'\D'), '').length != 14) {
                      return 'CNPJ Inválido (14 Dígitos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefone
                AuthTextField(
                  hintText:        '(XX) XXXXX-XXXX',
                  keyboardType:    TextInputType.phone,
                  controller:      _telefoneController,
                  inputFormatters: [PhoneMaskFormatter()],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o Telefone';
                    final d = v.replaceAll(RegExp(r'\D'), '');
                    if (d.length < 10 || d.length > 11) {
                      return 'Telefone Inválido (10 ou 11 Dígitos com DDD)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                AuthTextField(
                  hintText:     'email@dominio.com',
                  keyboardType: TextInputType.emailAddress,
                  controller:   _emailController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o E-mail';
                    if (!v.contains('@') || !v.contains('.')) return 'E-mail Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CEP
                AuthTextField(
                  hintText:        'CEP',
                  keyboardType:    TextInputType.number,
                  controller:      _cepController,
                  inputFormatters: [_cepFormatter],
                  onChanged:       _onCepChanged,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o CEP';
                    if (v.replaceAll(RegExp(r'\D'), '').length != 8) return 'CEP Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cidade + UF
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AuthTextField(
                        hintText:   'Cidade',
                        controller: _cidadeController,
                        validator:  (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe a Cidade';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value:         _selectedUf,
                        isExpanded:    true,
                        dropdownColor: colorScheme.surfaceContainer,
                        decoration: InputDecoration(
                          hintText:  'UF',
                          hintStyle: TextStyle(
                            color:    colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical:   16,
                          ),
                          filled:    true,
                          fillColor: colorScheme.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color:    colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        items: const [
                          'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA',
                          'MG','MS','MT','PA','PB','PE','PI','PR','RJ','RN',
                          'RO','RR','RS','SC','SE','SP','TO',
                        ]
                            .map((uf) => DropdownMenuItem(
                                  value: uf,
                                  child: Text(uf),
                                ))
                            .toList(),
                        onChanged: (uf) => setState(() {
                          _selectedUf        = uf;
                          _ufController.text = uf ?? '';
                        }),
                        validator: (_) => _selectedUf == null ? 'UF' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rua + Número
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AuthTextField(
                        hintText:  'Rua',
                        controller: _ruaController,
                        validator:  (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe a Rua';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: AuthTextField(
                        hintText:  'N°',
                        controller: _numeroController,
                        validator:  (v) {
                          if (v == null || v.trim().isEmpty) return 'N°';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  hintText:  'Complemento',
                  controller: _complementoController,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  hintText:  'Bairro',
                  controller: _bairroController,
                  validator:  (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o Bairro';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  hintText:  'Descrição do Hotel',
                  controller: _descricaoController,
                ),
                const SizedBox(height: 16),

                // Senha com olhinho
                _buildPasswordField(
                  controller: _senhaController,
                  hint:       'Senha',
                  obscure:    _obscureSenha,
                  onToggle:   () => setState(() => _obscureSenha = !_obscureSenha),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a Senha';
                    final erros = <String>[];
                    if (!RegExp(r'[A-Z]').hasMatch(v)) erros.add('• Uma letra maiúscula');
                    if (!RegExp(r'[a-z]').hasMatch(v)) erros.add('• Uma letra minúscula');
                    if (!RegExp(r'[0-9]').hasMatch(v)) erros.add('• Um número');
                    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) erros.add('• Um caractere especial');
                    if (erros.isEmpty) return null;
                    return 'A senha precisa ter:\n${erros.join('\n')}';
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar senha com olhinho
                _buildPasswordField(
                  controller: _confirmController,
                  hint:       'Confirmar Senha',
                  obscure:    _obscureConfirm,
                  onToggle:   () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _senhaController.text) return 'As Senhas Não Coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Checkbox de termos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value:       _termsAccepted,
                      activeColor: AppColors.secondary,
                      onChanged:   (v) =>
                          setState(() => _termsAccepted = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _termsAccepted = !_termsAccepted),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color:    colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: 'Concordo com os '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: _showTermsModal,
                                  child: const Text(
                                    'Termos e Condições',
                                    style: TextStyle(
                                      color:           AppColors.secondary,
                                      fontSize:        14,
                                      fontWeight:      FontWeight.w600,
                                      decoration:      TextDecoration.underline,
                                      decorationColor: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text:      'Cadastrar Hotel',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
