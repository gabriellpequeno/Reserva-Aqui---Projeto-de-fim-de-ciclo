import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import 'login_form.dart';
import 'user_signup_form.dart';

/// Opens the login modal sized for desktop. Returns the [AuthRole] when
/// authentication succeeds, or null when dismissed.
Future<AuthRole?> showLoginDialog(
  BuildContext context, {
  String role = 'guest',
}) {
  return showDialog<AuthRole>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AuthDialogShell(
      maxWidth: 480,
      child: LoginForm(
        role: role,
        onSuccess: (role) => Navigator.of(ctx).pop(role),
        onSecondary: () {
          Navigator.of(ctx).pop();
          showSignupChoiceDialog(context);
        },
      ),
    ),
  );
}

/// Modal that lets the user pick between "Sou hóspede" and "Sou anfitrião".
/// Keeps the user inside the modal flow when picking guest signup; for host
/// signup we navigate to the dedicated page (the form is too large for a
/// dialog).
Future<void> showSignupChoiceDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AuthDialogShell(
      maxWidth: 460,
      child: _SignupChoiceContent(
        onGuest: () {
          Navigator.of(ctx).pop();
          showUserSignupDialog(context);
        },
        onHost: () {
          Navigator.of(ctx).pop();
          ctx.push('/auth/signup/host');
        },
        onLogin: () {
          Navigator.of(ctx).pop();
          showLoginDialog(context);
        },
      ),
    ),
  );
}

/// Guest signup modal. Closes on success and routes to /home.
Future<void> showUserSignupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AuthDialogShell(
      maxWidth: 560,
      child: UserSignupForm(
        onSuccess: (_) {
          Navigator.of(ctx).pop();
          if (context.mounted) context.go('/home');
        },
        onSwitchToHost: () {
          Navigator.of(ctx).pop();
          if (context.mounted) context.push('/auth/signup/host');
        },
      ),
    ),
  );
}

class _SignupChoiceContent extends StatelessWidget {
  const _SignupChoiceContent({
    required this.onGuest,
    required this.onHost,
    required this.onLogin,
  });

  final VoidCallback onGuest;
  final VoidCallback onHost;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cadastre-se',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha como você quer usar o ReservAqui.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(text: 'Sou Hóspede', onPressed: onGuest),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Sou Anfitrião',
          color: AppColors.primary,
          textColor: Colors.white,
          onPressed: onHost,
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: onLogin,
            child: RichText(
              text: TextSpan(
                text: 'Já tem conta? ',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                children: const [
                  TextSpan(
                    text: 'Acesse Agora',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthDialogShell extends StatelessWidget {
  const _AuthDialogShell({required this.child, this.maxWidth = 600});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DialogHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'lib/assets/icons/logo/logoDark.svg'
        : 'lib/assets/icons/logo/logo.svg';

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 24, 24),
      child: Row(
        children: [
          SvgPicture.asset(asset, height: 24),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.close,
                    color: colorScheme.onSurface, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
