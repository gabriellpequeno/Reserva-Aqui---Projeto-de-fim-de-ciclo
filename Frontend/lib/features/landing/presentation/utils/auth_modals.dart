import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/user_or_host_page.dart';
import '../../../auth/presentation/pages/user_signup_page.dart';
import '../../../auth/presentation/pages/host_signup_page.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../profile/presentation/pages/host_profile_page.dart';
import '../../../profile/presentation/pages/admin_profile_page.dart';

const _kAuthModalMaxWidth = 480.0;
const _kProfileModalMaxWidth = 520.0;
const _kModalRadius = 20.0;

Widget _xButton(BuildContext ctx) => Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(ctx).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );

void _showModal(
  BuildContext context, {
  required Widget Function(BuildContext ctx) childBuilder,
  double maxWidth = _kAuthModalMaxWidth,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kModalRadius),
          child: Stack(
            children: [
              childBuilder(ctx),
              _xButton(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

void showLoginModal(BuildContext context) {
  _showModal(
    context,
    childBuilder: (ctx) => LoginPage(
      onSignupTap: () {
        Navigator.of(ctx).pop();
        showSignupModal(context);
      },
      onLoginDesktopSuccess: (role) {
        // Trigger the provider so MainLayout shows the profile modal after navigation.
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(postLoginProfileProvider.notifier).trigger(role);
        // Navigate to home via the router (no BuildContext needed).
        container.read(routerProvider).go('/home');
        // Close the dialog.
        Navigator.of(ctx).pop();
      },
    ),
  );
}

void showSignupModal(BuildContext context) {
  _showModal(
    context,
    childBuilder: (ctx) => UserOrHostPage(
      onUserTap: () {
        Navigator.of(ctx).pop();
        showUserSignupModal(context);
      },
      onHostTap: () {
        Navigator.of(ctx).pop();
        showHostSignupModal(context);
      },
      onLoginTap: () {
        Navigator.of(ctx).pop();
        showLoginModal(context);
      },
    ),
  );
}

void showUserSignupModal(BuildContext context) {
  _showModal(
    context,
    childBuilder: (ctx) => UserSignUpPage(
      onHostSignupTap: () {
        Navigator.of(ctx).pop();
        showHostSignupModal(context);
      },
    ),
  );
}

void showHostSignupModal(BuildContext context) {
  _showModal(
    context,
    childBuilder: (_) => const HostSignUpPage(),
  );
}

void showUserProfileModal(BuildContext context) {
  _showModal(
    context,
    maxWidth: _kProfileModalMaxWidth,
    childBuilder: (_) => const UserProfilePage(isModal: true),
  );
}

void showHostProfileModal(BuildContext context) {
  _showModal(
    context,
    maxWidth: _kProfileModalMaxWidth,
    childBuilder: (_) => const HostProfilePage(isModal: true),
  );
}

void showAdminProfileModal(BuildContext context) {
  _showModal(
    context,
    maxWidth: _kProfileModalMaxWidth,
    childBuilder: (_) => const AdminProfilePage(isModal: true),
  );
}

void showProfileModalForRole(BuildContext context, AuthRole role) {
  switch (role) {
    case AuthRole.host:
      showHostProfileModal(context);
    case AuthRole.admin:
      showAdminProfileModal(context);
    case AuthRole.guest:
      showUserProfileModal(context);
  }
}
