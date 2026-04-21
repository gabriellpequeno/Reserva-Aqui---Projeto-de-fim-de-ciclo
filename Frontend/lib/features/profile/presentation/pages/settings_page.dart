import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  final Color _labelColor = const Color(0xFF8B93A0); // Greyish-blue from the design
  final Color _borderColor = const Color(0xFFDCDFE5); // Lighter border color

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = MediaQuery.of(context).platformBrightness;
    _darkModeEnabled = brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60), // Adjusted space below CustomAppBar
              const Text(
                'Configurações',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 32),
              
              // Preferencias Section
              Text(
                'Preferencias',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_none,
                      title: 'Notificações',
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      },
                    ),
                    Divider(color: _borderColor, height: 1, indent: 16, endIndent: 16),
                    _buildSwitchTile(
                      icon: Icons.light_mode_outlined,
                      title: 'Modo Claro',
                      subtitle: 'Preferência De Tema',
                      value: _darkModeEnabled,
                      onChanged: (val) {
                        setState(() {
                          _darkModeEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Legal Section
              Text(
                'Legal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.list_alt,
                      title: 'Termos De Uso',
                      onTap: () {},
                    ),
                    Divider(color: _borderColor, height: 1, indent: 16, endIndent: 16),
                    _buildActionTile(
                      icon: Icons.privacy_tip_outlined, // Shield icon
                      title: 'Privacidade',
                      onTap: () {},
                    ),
                    Divider(color: _borderColor, height: 1, indent: 16, endIndent: 16),
                    _buildActionTile(
                      icon: Icons.info_outline,
                      title: 'Sobre O App',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _labelColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: _labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: _labelColor.withAlpha(178),
                    ),
                  ),
                ]
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.secondary, // Orange color
            inactiveTrackColor: _borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: _labelColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: _labelColor,
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
