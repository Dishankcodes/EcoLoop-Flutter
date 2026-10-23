import 'package:flutter/material.dart';

import '../../app_theme/user/app_colors.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _section(
        '1. Who operates EcoLoop',
        'This policy applies to EcoLoop, a platform project operated by the EcoLoop team for users in India. For operator-related questions, privacy requests or formal correspondence, contact ecoloopp2026@gmail.com. The team should publish its formal legal name and business address before commercial launch; these details cannot be inferred from the app code.',
      ),

      _section(
        '2. Information we may process',
        'Depending on the features used, EcoLoop may process names, email addresses, phone numbers, profile photos and location information; authentication records such as OTP verification data, password hashes, password-reset records and session identifiers; product listings, descriptions, prices and images; wishlist entries; orders, delivery and tracking details; payment-method status; donation and pickup requests; reviews and ratings; follows; notifications; rewards and Eco Impact records; and custom-service requests, budgets, reference images and ReMaker responses. Exact fields and collection points must be verified against the live app and backend.',
      ),

      _section(
        '3. How information is used',
        'Information may be used to create and secure accounts, verify sign-in requests, operate profiles and listings, facilitate orders using COD/offline arrangements, manage donations and pickup requests, support delivery and tracking, operate reviews, wishlists and follows, process custom-service requests and responses, provide notifications and impact summaries, respond to support requests, maintain records, troubleshoot the service and address misuse.',
      ),

      _section(
        '4. Public profiles, listings and images',
        'User and ReMaker profiles and marketplace listings are intended to be public. Information deliberately displayed there—such as display name, biography, portfolio content, product descriptions, prices, images and public reviews—may be viewed, copied or shared by others. Do not place private contact details, home addresses, identity documents or confidential information in public fields or images. Some media may use Google Drive links. EcoLoop works to make public media accessible for its intended purpose; users should not upload confidential material to public profile or listing fields.',
      ),

      _section(
        '5. Information that should not be public',
        'Passwords, password hashes, OTPs, reset tokens, session tokens, private delivery addresses, private contact fields and non-public account or order records should not be exposed through public profiles, listings or unauthorised API responses. Server-side access controls and API responses require a security review to verify this.',
      ),

      _section(
        '6. Service providers and sharing',
        'EcoLoop uses Google Apps Script and Google Sheets for backend/API and data storage, Google Drive for certain uploaded media, and email services for verification or account-related messages. These services form part of the current technical setup. The providers involved may change as features are enabled; when an online payment option is enabled, the relevant payment provider may process transaction information under its own terms and privacy notice. Information may also be disclosed where required by law or reasonably necessary to address security, fraud, safety or legal claims.',
      ),

      _section(
        '7. Payments',
        'The payment methods available for a particular order are the methods displayed in the live checkout. These may include COD or offline payment and, only where enabled, an online payment provider such as Razorpay. Backend endpoints or app code alone do not establish that a provider is live. If online payment is offered, transaction details may be processed by that provider; EcoLoop should treat an order as paid only after server-side verification confirms the transaction. Provider terms and privacy notices also apply.',
      ),

      _section(
        '8. Location and delivery',
        'City or location information may be used to show relevant listings, assess delivery or donation pickup availability, estimate delivery charges where configured and coordinate fulfilment. Privacy and location switches currently shown in Settings may not change server-side visibility or permissions. Do not rely on these switches as a guarantee that information is hidden or deleted; use the support contact for privacy requests.',
      ),

      _section(
        '9. Retention',
        'A final data-retention schedule has not been approved. Different records may be retained for account operation, orders, dispute handling, security, legal compliance and backups. Information may remain in backups or third-party systems for a limited period after a deletion request where needed for security, recovery or legal compliance, subject to applicable law.',
      ),

      _section(
        '10. Account closure and deletion',
        'The current account-closure behaviour is understood to deactivate an account and revoke sessions, but it does not necessarily erase related orders, reviews, other records or media stored in Drive or other systems. Account closure must not be described as complete erasure. Deletion requests are reviewed individually; some transaction, security or legally required records may need to be retained. Contact support for a request and any applicable follow-up. Contact support to make a privacy or deletion request.',
      ),

      _section(
        '11. Security',
        'EcoLoop uses authentication mechanisms that include OTP and password-related functions. No online service can guarantee absolute security. Keep credentials private and never share OTPs. Session lifetime configuration, access controls, Drive permissions, backups and incident-response procedures require technical review; no stronger security guarantee is made here.',
      ),

      _section(
        '12. Your choices and requests',
        'You may contact EcoLoop to request access to information, correction of inaccurate information, account assistance or details about deletion. Some in-app controls may not yet implement all privacy choices. Email ecoloopp2026@gmail.com and describe your request. Do not include passwords, OTPs or session tokens in your message.',
      ),

      _section(
        '13. Children and minimum age',
        'EcoLoop’s account and marketplace features are intended for people aged 18 or older. EcoLoop does not knowingly invite people under 18 to create accounts. If you believe a person under 18 has provided personal information, contact ecoloopp2026@gmail.com so the request can be reviewed.',
      ),

      _section(
        '14. Policy changes',
        'This policy may be revised as features and legal requirements change. This version was reviewed on 24 October 2026. Material changes may be notified through the app or another reasonable channel where required by law. Users should review this policy periodically.',
      ),

      _section(
        '15. Contact and grievances',
        'For privacy questions, account concerns or grievances, contact ecoloopp2026@gmail.com. For a privacy complaint or grievance, email ecoloopp2026@gmail.com with the subject “Privacy / Grievance Request”. Include enough information to identify the issue, but never send passwords, OTPs or session tokens. The EcoLoop team is the current contact point. Before commercial launch, the operator must confirm and publish any grievance-officer designation, postal address and statutory details required by applicable Indian law.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How EcoLoop handles your information.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Policy information describes current intended practices. Contact EcoLoop support for questions about data use or your privacy rights.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...sections,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Icon(Icons.eco_outlined, color: AppColors.primary, size: 25),
                  const SizedBox(height: 6),
                  Text(
                    'EcoLoop',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Privacy contact: ecoloopp2026@gmail.com\n'
                    'Reviewed: 24 October 2026. This policy does not limit rights available under applicable law.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last reviewed: 24 October 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.fromLTRB(20, 17, 20, 19),
    color: AppColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 11,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
