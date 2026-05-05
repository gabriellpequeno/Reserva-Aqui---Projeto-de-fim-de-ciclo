import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/admin_profile_provider.dart';
import '../widgets/profile_form_section.dart';

class EditAdminProfilePage extends ConsumerStatefulWidget {
  const EditAdminProfilePage({super.key});

  @override
  ConsumerState<EditAdminProfilePage> createState() =>
      _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends ConsumerState<EditAdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _prefilled = false;
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(adminProfileProvider.notifier);

      // Sempre envia apenas os campos realmente preenchidos; o service já
      // descarta strings vazias antes de bater no PATCH.
      await notifier.updateProfile(
        nomeCompleto: _nameController.text,
        email: _emailController.text,
        numeroCelular: _phoneController.text,
      );

      // Troca de senha é opcional — só dispara se nova senha foi preenchida.
      if (_passwordController.text.isNotEmpty) {
        await notifier.changePassword(
          senhaAtual: _currentPasswordController.text,
          novaSenha: _passwordController.text,
          confirmarNovaSenha: _confirmPasswordController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso')),
      );
      context.pop();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar: $err'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(adminProfileProvider);

    // Pré-preenche os campos na primeira vez que o provider entrega dados.
    asyncProfile.whenData((profile) {
      if (!_prefilled) {
        _nameController.text = profile.nome;
        _emailController.text = profile.email;
        _phoneController.text = profile.telefone ?? '';
        _prefilled = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: SafeArea(
            child: asyncProfile.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.greyText, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Não foi possível carregar o perfil.\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(adminProfileProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (_) => _buildForm(),
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
              'Editar Perfil Admin',
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
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Email é obrigatório';
                    if (!v!.contains('@')) return 'Email inválido';
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
                  onToggle: () => setState(
                    () => _obscureCurrentPassword = !_obscureCurrentPassword,
                  ),
                  validator: (v) {
                    if (_passwordController.text.isNotEmpty &&
                        (v?.isEmpty ?? true)) {
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
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  hint: 'Deixe em branco para manter a senha atual',
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  validator: (v) {
                    if (_passwordController.text.isNotEmpty &&
                        v != _passwordController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: _isLoading ? 'Salvando...' : 'Salvar Alterações',
              isLoading: _isLoading,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.pop(),
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
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.primary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        labelStyle: const TextStyle(color: AppColors.greyText, fontSize: 14),
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
      style: const TextStyle(color: AppColors.primary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.secondary,
          ),
        ),
        labelStyle: const TextStyle(color: AppColors.greyText, fontSize: 14),
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
