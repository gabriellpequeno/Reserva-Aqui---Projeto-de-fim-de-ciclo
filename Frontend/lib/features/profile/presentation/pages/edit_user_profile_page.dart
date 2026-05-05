import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile_form_section.dart';
import '../../../../utils/Usuario.dart';

class EditUserProfilePage extends ConsumerStatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  ConsumerState<EditUserProfilePage> createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends ConsumerState<EditUserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdateController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  final _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoadingPassword = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;

    // Converter data de YYYY-MM-DDTHH:mm:ss para DD/MM/AAAA
    String birthDateStr = profile?.dataNascimento ?? '';
    if (birthDateStr.isNotEmpty) {
      try {
        if (birthDateStr.contains('T')) {
          birthDateStr = birthDateStr.split('T')[0];
        }
        final parts = birthDateStr.split('-');
        if (parts.length == 3) {
          birthDateStr = '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      } catch (_) {}
    }

    String phone = profile?.numeroCelular ?? '';
    if (phone.length == 11) {
      phone = '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      phone = '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
    }

    _nameController = TextEditingController(text: profile?.nomeCompleto ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: phone);
    _birthdateController = TextEditingController(text: birthDateStr);
    _currentPasswordController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Salvar dados pessoais
    final successPersonal = await _savePersonalData();
    if (!successPersonal) return;

    // Se a senha estiver preenchida, tenta salvar a senha
    if (_passwordController.text.isNotEmpty) {
      await _savePassword();
      // O pop() já acontece dentro do _savePassword em caso de sucesso
    } else {
      // Se não tem senha pra mudar, e o personal deu certo, volta agora
      if (mounted) context.pop();
    }
  }

  Future<bool> _savePersonalData() async {
    setState(() => _isLoading = true);
    final completer = Completer<bool>();

    try {
      await ref.read(usuarioServiceProvider).update(
            nomeCompleto: _nameController.text,
            email: _emailController.text,
            numeroCelular: _phoneController.text,
            dataNascimento: _birthdateController.text,
            onSuccess: (u) {
              ref.invalidate(userProfileProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil atualizado com sucesso ✓')),
              );
              completer.complete(true);
            },
            onError: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
              completer.complete(false);
            },
          );
      return await completer.future;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() => _isLoadingPassword = true);
    final completer = Completer<void>();

    try {
      await ref.read(usuarioServiceProvider).changePassword(
            senhaAtual: _currentPasswordController.text,
            novaSenha: _passwordController.text,
            confirmarNovaSenha: _confirmPasswordController.text,
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha alterada com sucesso ✓')),
              );
              if (mounted) context.pop();
              completer.complete();
            },
            onError: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
              completer.complete();
            },
          );
      await completer.future;
    } finally {
      if (mounted) setState(() => _isLoadingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Editar Perfil',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                ProfileFormSection(
                  title: 'Informações Pessoais',
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome Completo',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Email é obrigatório';
                        }
                        if (!value!.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                     _buildTextField(
                      controller: _phoneController,
                      label: 'Número de Celular',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _BrazilianPhoneFormatter(),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Celular é obrigatório';
                        }
                        final clean = value!.replaceAll(RegExp(r'\D'), '');
                        if (clean.length != 10 && clean.length != 11) {
                          return 'Telefone incompleto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _birthdateController,
                      label: 'Data de Nascimento',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [_dateMask],
                      hint: 'DD/MM/YYYY',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Data de nascimento é obrigatória';
                        }
                        final clean = value!.replaceAll(RegExp(r'\D'), '');
                        if (clean.length != 8) {
                          return 'Data incompleta';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ProfileFormSection(
                  title: 'Segurança',
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: 'Senha Atual',
                      icon: Icons.lock_outline,
                      obscure: _obscureCurrentPassword,
                      onToggle: () {
                        setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                      },
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty && (value?.isEmpty ?? true)) {
                          return 'Insira sua senha atual para alterar';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Nova Senha',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      onToggle: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      hint: 'Deixe em branco para manter a senha atual',
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Senha',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      onToggle: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'As senhas não conferem';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: (_isLoading || _isLoadingPassword) ? 'Salvando...' : 'Salvar Alterações',
                  isLoading: _isLoading || _isLoadingPassword,
                  onPressed: (_isLoading || _isLoadingPassword) ? null : _handleSave,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: (_isLoading || _isLoadingPassword) ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      minLines: maxLines == 1 ? 1 : maxLines,
      validator: validator,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        labelStyle: const TextStyle(
          color: AppColors.greyText,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.strokeLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.strokeLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.secondary,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.greyText,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.strokeLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.strokeLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) return oldValue;

    String formatted = '';
    if (text.isNotEmpty) {
      formatted += '(';
      formatted += text.substring(0, text.length > 2 ? 2 : text.length);
      if (text.length > 2) {
        formatted += ') ';
        if (text.length <= 10) {
          formatted += text.substring(2, text.length > 6 ? 6 : text.length);
          if (text.length > 6) {
            formatted += '-';
            formatted += text.substring(6);
          }
        } else {
          formatted += text.substring(2, 7);
          formatted += '-';
          formatted += text.substring(7);
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
