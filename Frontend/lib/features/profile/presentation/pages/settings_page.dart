import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/utils/breakpoints.dart';

const _notificationsKey = 'notifications_enabled';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsPref();
  }

  Future<void> _loadNotificationsPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: isDesktop
            ? _buildDesktop(context, isDark)
            : _buildMobile(context, isDark),
      ),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gerencie suas preferências e informações legais.',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 36),
              // 2-col grid
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _desktopCard(
                        context: context,
                        icon: Icons.tune,
                        sectionTitle: 'PREFERÊNCIAS',
                        children: [
                          _desktopSwitchRow(
                            context: context,
                            icon: Icons.notifications_none_rounded,
                            title: 'Notificações',
                            subtitle: 'Alertas de reservas e mensagens',
                            value: _notificationsEnabled,
                            onChanged: _setNotifications,
                          ),
                          Divider(
                              height: 1,
                              color: colorScheme.outline
                                  .withValues(alpha: 0.6)),
                          _desktopSwitchRow(
                            context: context,
                            icon: Icons.dark_mode_outlined,
                            title: 'Modo Escuro',
                            subtitle: 'Alterna entre tema claro e escuro',
                            value: isDark,
                            onChanged: (val) =>
                                ref.read(themeProvider.notifier).setDark(val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _desktopCard(
                        context: context,
                        icon: Icons.article_outlined,
                        sectionTitle: 'LEGAL',
                        children: [
                          _desktopLinkRow(
                            context: context,
                            icon: Icons.list_alt_rounded,
                            title: 'Termos de Uso',
                            onTap: () => context.push('/profile/terms'),
                          ),
                          Divider(
                              height: 1,
                              color: colorScheme.outline
                                  .withValues(alpha: 0.6)),
                          _desktopLinkRow(
                            context: context,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Política de Privacidade',
                            onTap: () => context.push('/profile/privacy'),
                          ),
                          Divider(
                              height: 1,
                              color: colorScheme.outline
                                  .withValues(alpha: 0.6)),
                          _desktopLinkRow(
                            context: context,
                            icon: Icons.info_outline_rounded,
                            title: 'Sobre o App',
                            onTap: () => context.push('/profile/about'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopCard({
    required BuildContext context,
    required IconData icon,
    required String sectionTitle,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _desktopSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  Widget _desktopLinkRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return _HoverLinkRow(
      icon: icon,
      title: title,
      onTap: onTap,
      colorScheme: colorScheme,
    );
  }

  // ── Mobile (original) ──────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveCenter(
      maxWidth: ContentMaxWidth.profile,
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preferencias',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.notifications_none,
                    title: 'Notificações',
                    value: _notificationsEnabled,
                    onChanged: _setNotifications,
                  ),
                  Divider(
                      color: colorScheme.outline,
                      height: 1,
                      indent: 16,
                      endIndent: 16),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Modo Escuro',
                    subtitle: 'Preferência de tema',
                    value: isDark,
                    onChanged: (val) =>
                        ref.read(themeProvider.notifier).setDark(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Legal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    context: context,
                    icon: Icons.list_alt,
                    title: 'Termos De Uso',
                    onTap: () => context.push('/profile/terms'),
                  ),
                  Divider(
                      color: colorScheme.outline,
                      height: 1,
                      indent: 16,
                      endIndent: 16),
                  _buildActionTile(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacidade',
                    onTap: () => context.push('/profile/privacy'),
                  ),
                  Divider(
                      color: colorScheme.outline,
                      height: 1,
                      indent: 16,
                      endIndent: 16),
                  _buildActionTile(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Sobre O App',
                    onTap: () => context.push('/profile/about'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hover link row (desktop) ────────────────────────────────────────────────

class _HoverLinkRow extends StatefulWidget {
  const _HoverLinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  State<_HoverLinkRow> createState() => _HoverLinkRowState();
}

class _HoverLinkRowState extends State<_HoverLinkRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: _hover
              ? AppColors.secondary.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _hover
                    ? AppColors.secondary
                    : widget.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _hover
                        ? AppColors.secondary
                        : widget.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _hover
                    ? AppColors.secondary
                    : widget.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
