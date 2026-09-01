import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool notificationsEnabled = true;
  bool emailUpdatesEnabled = true;
  bool locationEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text('Settings', style: AppTextStyles.title),
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          _buildSectionTitle('Preferences'),


          _buildSettingsCard(
            children: [

              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark appearance for EcoLoop',
                value: darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    darkModeEnabled = value;
                  });
                },
              ),

              _buildDivider(),

              _buildSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Receive updates about your activity',
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
              ),

              _buildDivider(),

              _buildSwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Updates',
                subtitle: 'Receive important updates by email',
                value: emailUpdatesEnabled,
                onChanged: (value) {
                  setState(() {
                    emailUpdatesEnabled = value;
                  });
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  _showLanguageSheet();
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: locationEnabled
                    ? 'Location services enabled'
                    : 'Location services disabled',
                trailing: Switch(
                  value: locationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      locationEnabled = value;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    locationEnabled = !locationEnabled;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          _buildSectionTitle('Account'),

          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  _showComingSoon('Edit Profile');
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () {
                  _showComingSoon('Change Password');
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          _buildSectionTitle('Privacy & Security'),

          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Manage your privacy preferences',
                onTap: () {
                  _showComingSoon('Privacy');
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Security',
                subtitle: 'Manage account security',
                onTap: () {
                  _showComingSoon('Security');
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          _buildSectionTitle('Support'),

          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help with EcoLoop',
                onTap: () {
                  _showComingSoon('Help & Support');
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read EcoLoop terms',
                onTap: () {
                  _showComingSoon('Terms & Conditions');
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About EcoLoop',
                subtitle: 'Learn more about EcoLoop',
                onTap: () {
                  _showComingSoon('About EcoLoop');
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'EcoLoop',
              style: AppTextStyles.title.copyWith(fontSize: 16),
            ),
          ),

          const SizedBox(height: 3),

          Center(
            child: Text(
              'Small Actions. Big Impact.',
              style: AppTextStyles.caption,
            ),
          ),

          const SizedBox(height: 5),

          Center(
            child: Text(
              'Version 1.0.0',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 9),
      child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
    );
  }

  // ==========================================================
  // SETTINGS CARD
  // ==========================================================

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(children: children),
    );
  }

  // ==========================================================
  // NORMAL TILE
  // ==========================================================

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            _buildIconBox(icon),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SWITCH TILE
  // ==========================================================

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      child: Row(
        children: [
          _buildIconBox(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ICON BOX
  // ==========================================================

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 21, color: AppColors.primary),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(height: 1, color: AppColors.accent.withOpacity(0.22)),
    );
  }

  // ==========================================================
  // LANGUAGE
  // ==========================================================

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Language', style: AppTextStyles.title),

              const SizedBox(height: 15),

              _languageOption('English', true),
              _languageOption('Hindi', false),
              _languageOption('Gujarati', false),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(String language, bool selected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        language,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // TEMPORARY
  // ==========================================================

  void _showComingSoon(String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page will be implemented in the next phase.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
