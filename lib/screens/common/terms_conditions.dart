import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/back_button.dart';

class TermsConditions extends StatelessWidget {
  const TermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Terms & Conditions",
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  "Please read these terms before using EcoLoop.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              _section(
                "1. Acceptance of Terms",
                "By accessing or using EcoLoop, you agree to follow these "
                    "Terms & Conditions. If you do not agree with these terms, "
                    "please do not use the application.",
              ),

              _section(
                "2. About EcoLoop",
                "EcoLoop is a platform designed to encourage reuse and "
                    "sustainable participation. It provides features that allow "
                    "users to explore, buy, sell, donate, and exchange reusable "
                    "items and interact with artists.",
              ),

              _section(
                "3. User Accounts",
                "Users are responsible for providing accurate information "
                    "during registration and for maintaining the confidentiality "
                    "of their account credentials. Users should not share their "
                    "passwords or knowingly provide false account information.",
              ),

              _section(
                "4. Artist Accounts",
                "Users who register as artists are responsible for the "
                    "information they provide about themselves, their skills, "
                    "and the products they offer through the platform.",
              ),

              _section(
                "5. Listings and Products",
                "Users and artists are responsible for the accuracy of "
                    "information provided in their listings. Items and products "
                    "should be described honestly and should comply with "
                    "applicable laws and platform requirements.",
              ),

              _section(
                "6. Buying and Selling",
                "EcoLoop provides a platform for interaction between users "
                    "and artists. Users should review item and product details "
                    "before placing an order. Final transaction rules may depend "
                    "on the payment, delivery, and marketplace systems implemented "
                    "by EcoLoop.",
              ),

              _section(
                "7. Donations and Exchanges",
                "Users may use available donation and exchange features to "
                    "give reusable items a new purpose. Users are responsible "
                    "for providing accurate information about the condition and "
                    "availability of items.",
              ),

              _section(
                "8. Prohibited Activities",
                "Users must not use EcoLoop for unlawful activities, "
                    "fraudulent listings, misleading information, abusive "
                    "behaviour, unauthorized access, or activities that may "
                    "harm other users or the platform.",
              ),

              _section(
                "9. Content and Images",
                "Users and artists are responsible for content, descriptions, "
                    "and images they upload. Uploaded content should not violate "
                    "the rights, privacy, or intellectual property of other people.",
              ),

              _section(
                "10. Reviews and Ratings",
                "Reviews and ratings should be genuine and based on actual "
                    "experiences. Users should not use reviews to harass, threaten, "
                    "mislead, or unfairly harm another user or artist.",
              ),

              _section(
                "11. Privacy",
                "EcoLoop may collect information required to provide account "
                    "and application functionality. Privacy practices and data "
                    "handling will be governed by the applicable Privacy Policy "
                    "once implemented.",
              ),

              _section(
                "12. Platform Availability",
                "EcoLoop aims to provide reliable services, but temporary "
                    "interruptions may occur because of maintenance, technical "
                    "issues, updates, or other circumstances.",
              ),

              _section(
                "13. Account Termination",
                "EcoLoop may restrict or terminate access to an account when "
                    "necessary to protect the platform, its users, or comply with "
                    "applicable requirements.",
              ),

              _section(
                "14. Changes to These Terms",
                "These Terms & Conditions may be updated as EcoLoop develops "
                    "new features and services. Updated terms will apply after "
                    "they are made available through the application.",
              ),

              _section(
                "15. Contact and Support",
                "For questions or concerns regarding the platform, users can "
                    "use the Help & Support section available within the application.",
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  "Note: These terms are intended as application-level "
                  "project content and should be reviewed and updated with "
                  "final legal, privacy, payment, and marketplace policies "
                  "before public commercial deployment.",
                  style: AppTextStyles.caption.copyWith(height: 1.5),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
