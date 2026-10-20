import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../common/about_ecoloop.dart';
import '../../common/help_support.dart';
import '../../common/terms_conditions.dart';
import 'change_password.dart';
import 'edit_profile.dart';

/// Settings for account preferences, privacy, security, and support.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool notificationsEnabled = true;
  bool emailUpdatesEnabled = true;
  bool locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
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
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: notificationsEnabled
                    ? 'Receive updates about your activity'
                    : 'Notifications are turned off',
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
                subtitle: emailUpdatesEnabled
                    ? 'Receive important updates by email'
                    : 'Email updates are turned off',
                value: emailUpdatesEnabled,
                onChanged: (value) {
                  setState(() {
                    emailUpdatesEnabled = value;
                  });
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfile()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
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
                onTap: _showPrivacySheet,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Security',
                subtitle: 'Manage account security',
                onTap: _showSecuritySheet,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupport()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read EcoLoop terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsConditions()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About EcoLoop',
                subtitle: 'Learn more about EcoLoop',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutEcoLoop()),
                  );
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

  /// Title header label for setting categories.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 9),
      child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
    );
  }

  /// Container card wrapping settings tile options in a styled block.
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Clickable navigation tile item.
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 21,
                    color: AppColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggle switch tile item for notification and email preferences.
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
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
        ),
      ),
    );
  }

  /// Styled background box wrapping leading category icons.
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

  /// Inset horizontal line separator for card lists.
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(height: 1, color: AppColors.accent.withOpacity(0.22)),
    );
  }

  /// Displays the modal sheet for managing user privacy controls.
  void _showPrivacySheet() {
    bool profileVisible = true;
    bool activityVisible = false;
    bool locationSharing = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Privacy & Data', style: AppTextStyles.title),
                      const SizedBox(height: 5),
                      Text(
                        'Choose what you are comfortable sharing on EcoLoop.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 15),
                      _privacySwitch(
                        title: 'Profile visibility',
                        subtitle:
                            'Let other EcoLoop users view your public profile',
                        value: profileVisible,
                        onChanged: (value) {
                          setSheetState(() {
                            profileVisible = value;
                          });
                        },
                      ),
                      _privacySwitch(
                        title: 'Marketplace activity',
                        subtitle:
                            'Show activity such as reviews and listings on your profile',
                        value: activityVisible,
                        onChanged: (value) {
                          setSheetState(() {
                            activityVisible = value;
                          });
                        },
                      ),
                      _privacySwitch(
                        title: 'Use location for recommendations',
                        subtitle:
                            'Use location to make nearby listings more relevant',
                        value: locationSharing,
                        onChanged: (value) {
                          setSheetState(() {
                            locationSharing = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'These switches are currently a UI preview. They do not change server-side visibility or location permissions until connected to your account backend.',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
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
          },
        );
      },
    );
  }

  /// Switch item rendered within the privacy bottom sheet.
  Widget _privacySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
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

  /// Displays the modal sheet detailing security features and active sessions.
  void _showSecuritySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Account Security', style: AppTextStyles.title),
                  const SizedBox(height: 5),
                  Text(
                    'Review the key protections for your account.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 15),
                  _securityItem(
                    Icons.password_rounded,
                    'Password',
                    'Use a strong, unique password and update it if you suspect it was exposed.',
                  ),
                  _securityItem(
                    Icons.verified_user_outlined,
                    'Account details',
                    'Keep your registered email and phone number accurate so you can be reached.',
                  ),
                  _securityItem(
                    Icons.phonelink_lock_outlined,
                    'Sign-in safety',
                    'Never share your password or one-time verification codes with anyone.',
                  ),
                  _securityItem(
                    Icons.devices_outlined,
                    'Signed-in devices',
                    'Device and session management is not available in this screen yet.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: const Text('Change Password'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Password updates, verification status and active-session controls need authentication-backend support. This screen does not claim to change them.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
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
      },
    );
  }

  /// Item tile rendered inside the account security bottom sheet.
  Widget _securityItem(IconData icon, String title, String subtitle) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  /// Displays a floating snackbar feedback message.
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
