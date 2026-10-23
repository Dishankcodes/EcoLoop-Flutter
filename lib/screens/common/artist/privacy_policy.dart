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
        'This policy applies to EcoLoop, a platform project operated by the EcoLoop team for ReMakers in India. For operator-related questions, privacy requests or formal correspondence, contact ecoloopp2026@gmail.com. The team should publish its formal legal name and business address before commercial launch; these details cannot be inferred from the app code.',
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
        'Your ReMaker profile and published listings are intended to be public. Information shown publicly may include your display name, bio, skills, public location information, portfolio content, published certificates, product details, prices, images and public reviews. Public content may be viewed, copied or shared by others. Do not upload private customer details, identity documents, confidential information or materials you do not have permission to publish. Do not upload confidential material to public profile, portfolio or listing fields. Publicly displayed media may be viewed, copied or shared by others.',
      ),

      _section(
        '5. Customer and transaction information',
        'You may receive customer information needed to handle an order or custom-service request, such as a customer’s name, contact details, delivery address, order details, budget or reference images. Use this information only for the relevant transaction, service, support request or lawful obligation. Do not publish, sell, scrape or reuse it for unrelated marketing without an appropriate lawful basis and permission.',
      ),

      _section(
        '6. Service providers and sharing',
        'The current technical setup uses Google Apps Script and Google Sheets for backend/API and data storage, Google Drive for certain uploaded media, and email services for verification or account-related messages. Providers may vary as features are enabled; where online payment is offered, the payment provider may process transaction data under its own terms and privacy notice. Information may also be disclosed where required by law or reasonably necessary to address security, fraud, safety or legal claims.',
      ),

      _section(
        '7. Payments and earnings',
        'Payment methods available for a particular order are shown in the live checkout and may vary by deployment and order eligibility. An online payment provider is used only if that option is enabled and presented at checkout. Earnings and analytics are platform records or summaries and do not by themselves prove that money has been collected, settled or paid out. Fees, payouts and settlement occur only according to a separately disclosed and operational process; do not assume automatic payouts.',
      ),

      _section(
        '8. Location and delivery',
        'City or location information may support relevant listings, delivery estimates, fulfilment and donation pickup availability. Settings switches relating to privacy or location may not change server-side visibility or permissions. Do not rely on these switches as a guarantee that information is hidden or deleted; contact support for privacy requests.',
      ),

      _section(
        '9. Retention',
        'A final retention schedule has not been approved. Account, portfolio, listing, order, review, analytics, custom-service and security records may have different retention needs. Information may remain in backups or third-party systems for a limited period after a deletion request where needed for security, recovery or legal compliance, subject to applicable law.',
      ),

      _section(
        '10. Account closure and deletion',
        'The current account-closure behaviour is understood to deactivate an account and revoke sessions, but it does not necessarily erase orders, reviews, analytics, custom-service records or stored media. Account closure must not be described as complete erasure. Deletion requests are reviewed individually; some transaction, security or legally required records may need to be retained. Contact support for a request and any applicable follow-up. Contact ecoloopp2026@gmail.com for a privacy or deletion request.',
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
        'EcoLoop’s account and marketplace features are intended for people aged 18 or older. EcoLoop does not knowingly invite people under 18 to create accounts. If you believe a person under 18 has provided personal information, contact ecoloopp2026@gmail.com so the request can be reviewed.',
      ),

      _section(
        '14. Policy changes',
        'This policy may be revised as features and legal requirements change. This version was reviewed on 24 October 2026. Material changes may be notified through the app or another reasonable channel where required by law. ReMakers should review this policy periodically.',
      ),

      _section(
        '15. Contact and grievances',
        'For privacy questions, account concerns or grievances, contact ecoloopp2026@gmail.com. For a privacy complaint or grievance, email ecoloopp2026@gmail.com with the subject “Privacy / Grievance Request”. Include enough information to identify the issue, but never send passwords, OTPs or session tokens. The EcoLoop team is the current contact point. Before commercial launch, the operator must confirm and publish any grievance-officer designation, postal address and statutory details required by applicable Indian law.',
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
                            'Policy information describes current intended practices. Contact EcoLoop support for questions about data use or your privacy rights.',
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
                    'Reviewed: 24 October 2026. This policy does not limit rights available under applicable law.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: ArtistColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last reviewed: 24 October 2026',
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
