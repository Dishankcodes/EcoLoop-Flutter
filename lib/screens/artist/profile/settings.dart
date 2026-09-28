import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../common/about_ecoloop.dart';
import '../../common/artist/help_support.dart';
import '../../common/terms_conditions.dart';
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
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ArtistColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 23),
        ),
        title: Text(
          'Settings',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 28),
        children: [
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
                    ? 'Receive updates about your shop and orders'
                    : 'Notifications are turned off',
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });

                  _showMessage(
                    value ? 'Notifications enabled' : 'Notifications disabled',
                  );
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

                  _showMessage(
                    value ? 'Email updates enabled' : 'Email updates disabled',
                  );
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
                  activeColor: ArtistColors.primary,
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

          const SizedBox(height: 21),

          _buildSectionTitle('Account'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your artist profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfile()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 21),

          _buildSectionTitle('Privacy & Security'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Manage your profile visibility and privacy',
                onTap: _showPrivacySheet,
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Security',
                subtitle: 'Manage your account security',
                onTap: _showSecuritySheet,
              ),
            ],
          ),

          const SizedBox(height: 21),

          _buildSectionTitle('Support'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help with your EcoLoop artist account',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtistHelpSupportScreen(),
                    ),
                  );
                },
              ),

              _buildDivider(),

              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read EcoLoop terms and conditions',
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

          const SizedBox(height: 22),

          Center(
            child: Text(
              'EcoLoop',
              style: ArtistTextStyles.title.copyWith(fontSize: 16),
            ),
          ),

          const SizedBox(height: 3),

          Center(
            child: Text(
              'Create. Reuse. Inspire.',
              style: ArtistTextStyles.caption,
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(
              'Artist Version 1.0.0',
              style: ArtistTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8),
      child: Text(
        title,
        style: ArtistTextStyles.title.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              _buildIconBox(icon),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ArtistColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              _buildIconBox(icon),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),

              Switch(
                value: value,
                activeColor: ArtistColors.primary,
                activeTrackColor: ArtistColors.light,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: ArtistColors.primary),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: ArtistColors.border.withOpacity(0.65)),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHandle(),

                const SizedBox(height: 17),

                Text(
                  'Choose Language',
                  style: ArtistTextStyles.title.copyWith(fontSize: 18),
                ),

                const SizedBox(height: 4),

                Text(
                  'Select your preferred language.',
                  style: ArtistTextStyles.caption.copyWith(fontSize: 11),
                ),

                const SizedBox(height: 12),

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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? ArtistColors.primary : ArtistColors.textSecondary,
      ),
      title: Text(
        language,
        style: ArtistTextStyles.bodyMedium.copyWith(
          fontSize: 13,
          color: ArtistColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_rounded,
              color: ArtistColors.primary,
              size: 19,
            )
          : null,
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });

        Navigator.pop(context);

        _showMessage('Language changed to $language');
      },
    );
  }

  void _showPrivacySheet() {
    bool profileVisible = true;
    bool activityVisible = false;
    bool locationSharing = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHandle(),

                      const SizedBox(height: 17),

                      Text(
                        'Privacy Preferences',
                        style: ArtistTextStyles.title.copyWith(fontSize: 18),
                      ),

                      const SizedBox(height: 13),

                      _privacySwitch(
                        title: 'Public Artist Profile',
                        subtitle:
                            'Allow other users to view your artist profile',
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

                      const SizedBox(height: 7),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ArtistColors.light,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: ArtistColors.primary,
                              size: 19,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                'Your privacy controls can be connected to your account settings when the backend is integrated.',
                                style: ArtistTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  height: 1.4,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12.5),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeColor: ArtistColors.primary,
            activeTrackColor: ArtistColors.light,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showSecuritySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHandle(),

                  const SizedBox(height: 17),

                  Text(
                    'Account Security',
                    style: ArtistTextStyles.title.copyWith(fontSize: 18),
                  ),

                  const SizedBox(height: 13),

                  _securityItem(
                    Icons.lock_outline_rounded,
                    'Password',
                    'Your account password is protected.',
                  ),

                  _securityItem(
                    Icons.verified_user_outlined,
                    'Account Verification',
                    'Your EcoLoop artist account verification status.',
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

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ArtistColors.light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Security management will be connected to the backend during the authentication phase.',
                      style: ArtistTextStyles.caption.copyWith(
                        fontSize: 10,
                        height: 1.4,
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12.5),
      ),
      subtitle: Text(
        subtitle,
        style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        height: 4,
        width: 40,
        decoration: BoxDecoration(
          color: ArtistColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 11.5,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}
