import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../mocks/mock_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = context.canPop();
    final String location = GoRouterState.of(context).uri.path;
    final bool isHome = location == '/' || location == '/home';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 100, // Increased height
      leading: (showBackButton && (!isHome || canPop))
          ? Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left, 
                  color: AppColors.primary, 
                  size: 32, // More prominent like in the print
                ),
                onPressed: () {
                  if (canPop) {
                    context.pop();
                  } else {
                    final role = MockAuth.currentUserRole;
                    if (role == UserRole.admin) {
                      context.go('/profile/admin');
                    } else if (role == UserRole.host) {
                      context.go('/profile/host');
                    } else {
                      context.go('/profile/user');
                    }
                  }
                },
              ),
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(top: 30.0), // Logo lower than real top
        child: SvgPicture.asset(
          'lib/assets/icons/logo/logo.svg',
          height: 32,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
