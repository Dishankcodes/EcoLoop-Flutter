import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../common/about_ecoloop.dart';
import '../common/help_support.dart';
import '../common/terms_conditions.dart';
import 'edit_profile.dart';

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

  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Settings', style: AppTextStyles.title),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          // ======================================================
          // PREFERENCES
          // ======================================================
          _buildSectionTitle('Preferences'),

          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: darkModeEnabled
                    ? 'Dark appearance enabled'
                    : 'Use dark appearance for EcoLoop',
                value: darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    darkModeEnabled = value;
                  });

                  _showMessage(
                    value ? 'Dark Mode enabled' : 'Dark Mode disabled',
                  );
                },
              ),

              _buildDivider(),

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
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: selectedLanguage,
                onTap: _showLanguageSheet,
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

          // ======================================================
          // ACCOUNT
          // ======================================================
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
                onTap: _showChangePasswordSheet,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ======================================================
          // PRIVACY & SECURITY
          // ======================================================
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

          // ======================================================
          // SUPPORT
          // ======================================================
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

          // ======================================================
          // FOOTER
          // ======================================================
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 9),
      child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

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

  // ============================================================
  // NORMAL CLICKABLE TILE
  // ============================================================

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

  // ============================================================
  // SWITCH TILE
  // ============================================================

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
        onTap: () {
          onChanged(!value);
        },
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
        ),
      ),
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

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

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(height: 1, color: AppColors.accent.withOpacity(0.22)),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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

                Text('Choose Language', style: AppTextStyles.title),

                const SizedBox(height: 5),

                const Text(
                  'Select your preferred language.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 15),

                _languageOption('English'),
                _languageOption('Hindi'),
                _languageOption('Gujarati'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption(String language) {
    final selected = selectedLanguage == language;

    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        trailing: selected
            ? const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              )
            : null,
        onTap: () {
          setState(() {
            selectedLanguage = language;
          });

          Navigator.pop(context);

          _showMessage('Language changed to $language');
        },
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

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
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 25,
                ),
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

                      Text('Change Password', style: AppTextStyles.title),

                      const SizedBox(height: 5),

                      const Text(
                        'Create a new password for your EcoLoop account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _passwordField(
                        controller: currentPasswordController,
                        label: 'Current Password',
                        obscure: obscureCurrent,
                        onToggle: () {
                          setSheetState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _passwordField(
                        controller: newPasswordController,
                        label: 'New Password',
                        obscure: obscureNew,
                        onToggle: () {
                          setSheetState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _passwordField(
                        controller: confirmPasswordController,
                        label: 'Confirm New Password',
                        obscure: obscureConfirm,
                        onToggle: () {
                          setSheetState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (newPasswordController.text.isEmpty ||
                                confirmPasswordController.text.isEmpty) {
                              _showMessage('Please enter your new password.');
                              return;
                            }

                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              _showMessage('Passwords do not match.');
                              return;
                            }

                            Navigator.pop(sheetContext);

                            _showMessage(
                              'Password update will be connected later.',
                            );
                          },
                          child: const Text('Update Password'),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRIVACY
  // ============================================================

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

                      Text('Privacy Preferences', style: AppTextStyles.title),

                      const SizedBox(height: 15),

                      _privacySwitch(
                        title: 'Public Profile',
                        subtitle: 'Allow other users to view your profile',
                        value: profileVisible,
                        onChanged: (value) {
                          setSheetState(() {
                            profileVisible = value;
                          });
                        },
                      ),

                      _privacySwitch(
                        title: 'Activity Visibility',
                        subtitle:
                            'Control visibility of your marketplace activity',
                        value: activityVisible,
                        onChanged: (value) {
                          setSheetState(() {
                            activityVisible = value;
                          });
                        },
                      ),

                      _privacySwitch(
                        title: 'Location Sharing',
                        subtitle:
                            'Allow location to improve marketplace results',
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
                                'Your privacy controls can be connected to your account settings when the backend is integrated.',
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

  // ============================================================
  // SECURITY
  // ============================================================

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

                  const SizedBox(height: 15),

                  _securityItem(
                    Icons.lock_outline_rounded,
                    'Password',
                    'Your account password is protected.',
                  ),

                  _securityItem(
                    Icons.verified_user_outlined,
                    'Account Verification',
                    'Your EcoLoop account verification status.',
                  ),

                  _securityItem(
                    Icons.devices_outlined,
                    'Active Sessions',
                    'Manage devices where your account is signed in.',
                  ),

                  _securityItem(
                    Icons.warning_amber_rounded,
                    'Security Alerts',
                    'Important security notifications will appear here.',
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Text(
                      'Security management will be connected to the backend during the authentication phase.',
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
          ),
        );
      },
    );
  }

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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
