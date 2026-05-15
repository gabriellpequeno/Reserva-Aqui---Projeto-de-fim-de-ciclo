import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/utils/breakpoints.dart';
import '../widgets/user_signup_form.dart';

class UserSignUpPage extends ConsumerWidget {
  const UserSignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: ContentMaxWidth.form,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
            child: UserSignupForm(
              onSuccess: (AuthRole _) {
                if (!context.mounted) return;
                context.go('/home');
              },
              onSwitchToHost: () => context.push('/auth/signup/host'),
            ),
          ),
        ),
      ),
    );
  }
}
