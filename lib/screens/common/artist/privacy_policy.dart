import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistPrivacyPolicy extends StatelessWidget {
  const ArtistPrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _section(
        '1. Who operates EcoLoop',
        'EcoLoop is identified in this draft as “EcoLoop”. Its formal legal entity details, business structure and registered or principal business address are Pending confirmation. This policy is intended for ReMakers using EcoLoop in India.',
      ),

      _section(
        '2. Information we may process',
        'Depending on features used, EcoLoop may process account and profile information, including name, email, phone number, profile photo, bio, skills and location; authentication records such as OTP verification data, password hashes, reset records and session identifiers; portfolio content and certificates; product listings, prices, descriptions, quantities and images; orders, delivery and tracking details; payment-method status; reviews and ratings; followers and follows; notifications; analytics and earnings summaries; and custom-service requests, budgets, reference images and proposals. Exact fields and collection points must be checked against the live app and backend.',
      ),

      _section(
        '3. How information is used',
        'Information may be used to authenticate accounts, display public profiles and portfolios, publish listings, manage orders and fulfilment, support customer communications, record reviews and follows, provide analytics and earnings summaries, facilitate custom-service proposals, send notifications, answer support requests, maintain records and investigate misuse.',
      ),

      _section(
        '4. Public profile, portfolio and listings',
        'Your ReMaker profile and published listings are intended to be public. Information shown publicly may include your display name, bio, skills, public location information, portfolio content, published certificates, product details, prices, images and public reviews. Public content may be viewed, copied or shared by others. Do not upload private customer details, identity documents, confidential information or materials you do not have permission to publish. Whether all uploaded media has appropriate Google Drive permissions is Pending technical verification.',
      ),

      _section(
        '5. Customer and transaction information',
        'You may receive customer information needed to handle an order or custom-service request, such as a customer’s name, contact details, delivery address, order details, budget or reference images. Use this information only for the relevant transaction, service, support request or lawful obligation. Do not publish, sell, scrape or reuse it for unrelated marketing without an appropriate lawful basis and permission.',
      ),

      _section(
        '6. Service providers and sharing',
        'The current technical setup uses Google Apps Script and Google Sheets for backend/API and data storage, Google Drive for certain uploaded media, and email services for verification or account-related messages. Whether other providers receive information is Pending confirmation. Information may also be disclosed where required by law or reasonably necessary to address security, fraud, safety or legal claims.',
      ),

      _section(
        '7. Payments and earnings',
        'EcoLoop currently supports Cash on Delivery (COD) and/or offline payment arrangements only. Online payment gateway processing is not active. Earnings or analytics shown in the app may be system-generated records or summaries and do not necessarily mean money has been collected, settled or automatically paid out. Commission, platform fees, payout methods and settlement timelines are Pending unless explicitly confirmed by the live workflow.',
      ),

      _section(
        '8. Location and delivery',
        'City or location information may support relevant listings, delivery estimates, fulfilment and donation pickup availability. Settings switches relating to privacy or location may not change server-side visibility or permissions. Their actual effect is Pending technical verification.',
      ),

      _section(
        '9. Retention',
        'A final retention schedule has not been approved. Account, portfolio, listing, order, review, analytics, custom-service and security records may have different retention needs. Exact retention periods and deletion from backups or third-party storage are Pending.',
      ),

      _section(
        '10. Account closure and deletion',
        'The current account-closure behaviour is understood to deactivate an account and revoke sessions, but it does not necessarily erase orders, reviews, analytics, custom-service records or stored media. Account closure must not be described as complete erasure. The deletion-request process, retained categories and completion timeline are Pending confirmation. Contact ecoloopp2026@gmail.com for a privacy or deletion request.',
      ),

      _section(
        '11. Security',
        'EcoLoop uses authentication mechanisms that include OTP and password-related functions. No online service can guarantee absolute security. Keep credentials private and never share OTPs. Session lifetime configuration, access controls, Drive permissions, backups and incident-response procedures require technical review.',
      ),

      _section(
        '12. Your choices and requests',
        'You may contact EcoLoop to request access to information, correction of inaccurate information, account assistance or details about deletion. Some in-app privacy controls may not yet implement all available choices. Email ecoloopp2026@gmail.com. Do not include passwords, OTPs or session tokens in your message.',
      ),

      _section(
        '13. Children and minimum age',
        'EcoLoop’s minimum permitted age is Pending. The age threshold and any required parental-consent process must be decided and implemented before this policy is finalised and published.',
      ),

      _section(
        '14. Policy changes',
        'This policy may be revised as features and legal requirements change. The effective date and method for notifying ReMakers of material changes are Pending implementation. The published version should show the actual current version and effective date.',
      ),

      _section(
        '15. Contact and grievances',
        'For privacy questions, account concerns or grievances, contact ecoloopp2026@gmail.com. The designated grievance officer’s name, role, postal address, response timeline and formal grievance-handling process are Pending confirmation against applicable Indian requirements.',
      ),
    ];

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Privacy Policy',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: ArtistColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: ArtistColors.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How EcoLoop handles ReMaker information.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ArtistColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Draft for review. Unresolved legal and implementation details are marked Pending.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: ArtistColors.textSecondary,
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
                  Icon(
                    Icons.eco_outlined,
                    color: ArtistColors.primary,
                    size: 25,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'EcoLoop',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ArtistColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Privacy contact: ecoloopp2026@gmail.com\n'
                    'Draft — requires legal and technical review before publication.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: ArtistColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last reviewed: 20 October 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: ArtistColors.textSecondary,
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
    color: ArtistColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 11,
            height: 1.6,
            color: ArtistColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
