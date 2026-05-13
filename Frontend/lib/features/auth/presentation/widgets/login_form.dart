import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/auth_response.dart';
import 'auth_text_field.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({
    super.key,
    this.role = 'guest',
    this.onSuccess,
    this.onSecondary,
    this.secondaryLabel = 'Cadastre-se Agora',
    this.showSecondaryButton = true,
  });

  final String role;

  /// Called after successful login with the authenticated [AuthRole].
  final void Function(AuthRole role)? onSuccess;

  /// Called when the secondary button (signup) is tapped.
  final VoidCallback? onSecondary;

  final String secondaryLabel;
  final bool showSecondaryButton;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.role;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      late AuthResponse response;

      if (_role == 'host') {
        response = await authService.loginHotel(
          _emailController.text,
          _senhaController.text,
        );
      } else {
        try {
          response = await authService.loginGuest(
            _emailController.text,
            _senhaController.text,
          );
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 401) {
            response = await authService.loginHotel(
              _emailController.text,
              _senhaController.text,
            );
            _role = 'host';
          } else {
            rethrow;
          }
        }
      }

      final AuthRole role;
      if (_role == 'host') {
        role = AuthRole.host;
      } else if (response.papel == 'admin') {
        role = AuthRole.admin;
      } else {
        role = AuthRole.guest;
      }

      await ref
          .read(authProvider.notifier)
          .setAuth(response.accessToken, response.refreshToken, role);

      if (!mounted) return;
      widget.onSuccess?.call(role);
    } catch (e) {
      if (!mounted) return;

      String message = 'Erro ao realizar login. Tente novamente.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          message = 'E-mail ou senha incorretos.';
        } else if (e.response?.statusCode == 429) {
          message = 'Muitas tentativas. Aguarde alguns minutos.';
        } else {
          message = 'Erro de conexão: ${e.message}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _role == 'host' ? 'Acesso Anfitrião' : 'Acesse Agora',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: _emailController,
            hintText: 'email@domain.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe o e-mail';
              final emailRegex =
                  RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _senhaController,
            hintText: 'senha',
            isPassword: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe a senha';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(text: 'Login', onPressed: _submit),
          if (widget.showSecondaryButton) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              text: widget.secondaryLabel,
              color: AppColors.primary,
              textColor: Colors.white,
              onPressed:
                  widget.onSecondary ?? () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
