import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canPop = context.canPop();
    final String location = GoRouterState.of(context).uri.path;
    final bool isHome = location == '/' || location == '/home';
    final bool isProfile = location.startsWith('/profile');
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 100,
      leading: (showBackButton && (!isHome || canPop))
          ? Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: colorScheme.onSurface,
                  size: 32,
                ),
                onPressed: () {
                  if (canPop) {
                    context.pop();
                  } else if (isProfile) {
                    context.go('/home');
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
        child: SvgPicture.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'lib/assets/icons/logo/logoDark.svg'
              : 'lib/assets/icons/logo/logo.svg',
          height: 32,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
