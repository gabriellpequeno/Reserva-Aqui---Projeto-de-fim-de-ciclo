import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../widgets/login_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _role = extra?['role'] as String? ?? 'guest';
  }

  void _onLoginSuccess(AuthRole role) {
    if (!mounted) return;
    context.go(role == AuthRole.admin ? '/profile/admin' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Breakpoints.isDesktop(context)
          ? null
          : const CustomAppBar(fallbackRoute: '/home'),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: ContentMaxWidth.form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: LoginForm(
              role: _role,
              onSuccess: _onLoginSuccess,
              onSecondary: () => context.push('/auth'),
            ),
          ),
        ),
      ),
    );
  }
}
