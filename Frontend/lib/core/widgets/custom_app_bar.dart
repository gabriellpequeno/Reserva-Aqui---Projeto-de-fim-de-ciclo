import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../theme/app_colors.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.showBackButton = true,
    this.fallbackRoute,
    this.title,
    this.showNotificationIcon = false,
  });

  final bool showBackButton;
  final String? fallbackRoute;

  /// When non-null, displays this text centered instead of the logo.
  final String? title;

  /// When true, displays a notifications bell icon on the trailing side.
  final bool showNotificationIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canPop = context.canPop();
    final String location = GoRouterState.of(context).uri.path;
    final bool isHome = location == '/' || location == '/home';

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      leading: (showBackButton && (!isHome || canPop))
          ? Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  if (canPop) {
                    context.pop();
                  } else if (fallbackRoute != null) {
                    context.go(fallbackRoute!);
                  } else {
                    final auth = ref.read(authProvider).asData?.value;
                    if (auth?.role == AuthRole.host) {
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
        padding: const EdgeInsets.only(top: 30.0),
        child: title != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : SvgPicture.asset(
                'lib/assets/icons/logo/logoDark.svg',
                height: 32,
              ),
      ),
      actions: showNotificationIcon
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 30.0, right: 8.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => context.go('/notifications'),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
