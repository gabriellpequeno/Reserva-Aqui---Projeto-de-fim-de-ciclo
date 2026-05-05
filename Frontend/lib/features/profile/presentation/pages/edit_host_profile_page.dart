import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/via_cep.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/host_profile_provider.dart';
import '../widgets/profile_form_section.dart';

class EditHostProfilePage extends ConsumerStatefulWidget {
  const EditHostProfilePage({super.key});

  @override
  ConsumerState<EditHostProfilePage> createState() =>
      _EditHostProfilePageState();
}

class _EditHostProfilePageState extends ConsumerState<EditHostProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _cepController;
  late final TextEditingController _ufController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _bairroController;
  late final TextEditingController _ruaController;
  late final TextEditingController _numeroController;
  late final TextEditingController _complementoController;

  late final TextEditingController _currentPasswordController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  Map<String, String> _initial = const {};
  bool _isSubmitting = false;
  bool _initialized = false;
  bool _cepLookupLoading = false;
  String? _cepLookupError;
  Timer? _cepDebounce;

  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _descricaoController = TextEditingController();
    _cepController = TextEditingController();
    _ufController = TextEditingController();
    _cidadeController = TextEditingController();
    _bairroController = TextEditingController();
    _ruaController = TextEditingController();
    _numeroController = TextEditingController();
    _complementoController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _cepController.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cepDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descricaoController.dispose();
    _cepController.dispose();
    _ufController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _populateFromHotel(Map<String, dynamic> hotel) {
    String s(dynamic v) => (v ?? '').toString();

    final cepRaw = s(hotel['cep']);
    final cepMasked = _formatCep(cepRaw);

    _nameController.text = s(hotel['nome_hotel']);
    _emailController.text = s(hotel['email']);
    _phoneController.text = s(hotel['telefone']);
    _descricaoController.text = s(hotel['descricao']);
    _cepController.text = cepMasked;
    _ufController.text = s(hotel['uf']);
    _cidadeController.text = s(hotel['cidade']);
    _bairroController.text = s(hotel['bairro']);
    _ruaController.text = s(hotel['rua']);
    _numeroController.text = s(hotel['numero']);
    _complementoController.text = s(hotel['complemento']);

    _initial = {
      'nome_hotel': _nameController.text,
      'email': _emailController.text,
      'telefone': _phoneController.text,
      'descricao': _descricaoController.text,
      'cep': _onlyDigits(cepMasked),
      'uf': _ufController.text,
      'cidade': _cidadeController.text,
      'bairro': _bairroController.text,
      'rua': _ruaController.text,
      'numero': _numeroController.text,
      'complemento': _complementoController.text,
    };
  }

  String _formatCep(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return raw;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _onCepChanged() {
    _cepDebounce?.cancel();
    _cepDebounce = Timer(const Duration(milliseconds: 500), () async {
      final cepDigits = _onlyDigits(_cepController.text);
      if (cepDigits.length != 8) {
        if (_cepLookupError != null) {
          setState(() => _cepLookupError = null);
        }
        return;
      }

      setState(() {
        _cepLookupLoading = true;
        _cepLookupError = null;
      });

      final result = await fetchViaCep(cepDigits);

      if (!mounted) return;

      setState(() {
        _cepLookupLoading = false;
        if (result == null) {
          _cepLookupError = 'CEP não encontrado. Preencha manualmente.';
        } else {
          _cepLookupError = null;
          _ufController.text = result.uf;
          _cidadeController.text = result.cidade;
          _bairroController.text = result.bairro;
          _ruaController.text = result.rua;
        }
      });
    });
  }

  Map<String, dynamic> _buildDiff() {
    final current = <String, String>{
      'nome_hotel': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _phoneController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'cep': _onlyDigits(_cepController.text),
      'uf': _ufController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'rua': _ruaController.text.trim(),
      'numero': _numeroController.text.trim(),
      'complemento': _complementoController.text.trim(),
    };

    final diff = <String, dynamic>{};
    current.forEach((key, value) {
      if (value != (_initial[key] ?? '')) {
        diff[key] = value;
      }
    });
    return diff;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final wantsPasswordChange = _passwordController.text.isNotEmpty ||
        _currentPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;

    final diff = _buildDiff();

    if (diff.isEmpty && !wantsPasswordChange) {
      _showSnack('Nenhuma alteração a salvar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (diff.isNotEmpty) {
        try {
          await ref.read(hostProfileProvider.notifier).updateProfile(diff);
        } catch (e) {
          if (!mounted) return;
          _showSnack(_messageFrom(e));
          return;
        }
      }

      if (wantsPasswordChange) {
        if (_currentPasswordController.text.isEmpty) {
          _showSnack('Informe sua senha atual para alterá-la.');
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          _showSnack('As novas senhas não coincidem.');
          return;
        }

        try {
          await ref.read(hostProfileProvider.notifier).changePassword(
                senhaAtual: _currentPasswordController.text,
                novaSenha: _passwordController.text,
                confirmarNovaSenha: _confirmPasswordController.text,
              );
        } catch (e) {
          if (!mounted) return;
          _showSnack(_messageFrom(e));
          return;
        }

        if (!mounted) return;
        _showSnack('Senha alterada. Faça login novamente.');
        await ref.read(authProvider.notifier).clear();
        if (!mounted) return;
        context.go('/auth/login');
        return;
      }

      if (diff.isNotEmpty) {
        if (!mounted) return;
        _showSnack('Perfil atualizado com sucesso.');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFrom(Object e) {
    if (e is Exception) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
    return 'Erro inesperado. Tente novamente.';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(hostProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: SafeArea(
            child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar perfil:\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(hostProfileProvider),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (!_initialized) {
              _populateFromHotel(profile.hotel);
              _initialized = true;
            }
            return _buildForm();
          },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Editar Perfil de Host',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            ProfileFormSection(
              title: 'Informações do Hotel',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nome do Hotel',
                  icon: Icons.business_outlined,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
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
                    if (value?.trim().isEmpty ?? true) {
                      return 'Email é obrigatório';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Telefone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descricaoController,
                  label: 'Descrição',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ProfileFormSection(
              title: 'Endereço',
              children: [
                _buildTextField(
                  controller: _cepController,
                  label: 'CEP',
                  icon: Icons.location_on_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cepMask],
                  suffix: _cepLookupLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'CEP é obrigatório';
                    }
                    if (_onlyDigits(value!).length != 8) {
                      return 'CEP inválido';
                    }
                    return null;
                  },
                ),
                if (_cepLookupError != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _cepLookupError!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _cidadeController,
                        label: 'Cidade',
                        icon: Icons.location_city_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Cidade obrigatória';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _ufController,
                        label: 'UF',
                        icon: Icons.map_outlined,
                        maxLength: 2,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'UF';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bairroController,
                  label: 'Bairro',
                  icon: Icons.home_work_outlined,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Bairro obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ruaController,
                  label: 'Rua',
                  icon: Icons.signpost_outlined,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Rua obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _numeroController,
                        label: 'Número',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _complementoController,
                        label: 'Complemento',
                        icon: Icons.add_location_outlined,
                      ),
                    ),
                  ],
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
                    setState(() =>
                        _obscureCurrentPassword = !_obscureCurrentPassword);
                  },
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        (value?.isEmpty ?? true)) {
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
                  label: 'Confirmar Nova Senha',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: _isSubmitting ? 'Salvando...' : 'Salvar Alterações',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? () {} : _saveProfile,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? hint,
    Widget? suffix,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters?.cast(),
      validator: validator,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: maxLength != null ? '' : null,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(12),
                child: suffix,
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
