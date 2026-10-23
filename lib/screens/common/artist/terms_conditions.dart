import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistTermsConditions extends StatelessWidget {
  const ArtistTermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _section(
        '1. About these terms',
        'These terms apply to EcoLoop ReMaker features, including public profiles, portfolios, product listings, orders, followers, reviews, analytics and custom-service responses. EcoLoop facilitates platform features and is not automatically a party to every sale or commissioned-work agreement. EcoLoop is the platform name used by the project team. For operator and business-contact information, write to ecoloopp2026@gmail.com. The team should provide its formal legal name and business address in the public listing before commercial launch.',
      ),

      _section(
        '2. Acceptance and eligibility',
        'Using ReMaker features means you agree to these terms and the Privacy Policy. You must be at least 18 years old to use EcoLoop account and marketplace features. You must have the legal capacity and permissions needed to sell goods or provide services.',
      ),

      _section(
        '3. Account accuracy and security',
        'Keep account details accurate, protect credentials and never share OTPs or passwords. Report suspected account compromise promptly. Account recovery and email-change rules depend on the features actually available in the app.',
      ),

      _section(
        '4. Public ReMaker profile',
        'Your display name, bio, skills, public location information, portfolio, published certificates, products and reviews may be visible publicly. Publish only information you intend to make public. Do not upload identity documents, private customer details or confidential materials to public profile or portfolio fields.',
      ),

      _section(
        '5. Products and seller responsibilities',
        'You must be entitled to sell each item you list and provide accurate descriptions, condition, images, quantity, price and availability. Do not list illegal, stolen, counterfeit, unsafe or misleading items. You are responsible for fulfilling orders as described, communicating material changes and complying with applicable laws relevant to your activity.',
      ),

      _section(
        '6. Orders, delivery and COD',
        'Use only the payment method displayed and agreed for the specific order. Depending on deployment and order eligibility, checkout may offer COD, an offline arrangement or an online payment provider. Online payment is not confirmed merely because a provider app opens or a customer returns to EcoLoop; fulfilment and payment records must reflect verified status. Follow the order details and keep customer information confidential, using it only for that transaction. Cancellation, return, refund and delivery remedies are subject to the in-app options, the seller agreement and applicable consumer law.',
      ),

      _section(
        '7. Earnings and fees',
        'Earnings or analytics displayed in the app are system records or summaries and do not necessarily mean money has been collected or settled by EcoLoop. Any commission, platform fee, payout method or settlement timing must be shown in the applicable seller terms or transaction flow. Artists remain responsible for their own tax and accounting obligations. Do not assume online payment processing or automatic payouts are available.',
      ),

      _section(
        '8. Custom-service proposals',
        'When responding to a custom-service request, describe the scope, deliverables, price, timeline, revisions, materials, delivery or collection arrangements and acceptance conditions clearly. Do not accept work you cannot reasonably complete. Agree in writing with the customer on deposits, cancellation, refunds, ownership or licensing, deadlines and dispute handling before accepting the work, subject to applicable law. Use customer reference images only for the requested purpose and do not republish them without permission.',
      ),

      _section(
        '9. Reviews, followers and conduct',
        'Do not buy, fabricate or manipulate reviews, or retaliate against reviewers. Do not harass users, spam followers, impersonate others or misrepresent skills, certificates, materials or past work. Public reviews and profile content may remain after account deactivation, subject to applicable law and the final retention policy.',
      ),

      _section(
        '10. Customer privacy and confidentiality',
        'Customer names, phone numbers, delivery addresses, order details, budgets, reference images and private communications must not be disclosed, sold, scraped, reused for unrelated marketing or posted publicly without a lawful basis and appropriate permission. Use such information only for the relevant order, custom service, support or legal obligation.',
      ),

      _section(
        '11. Donations and platform features',
        'If you participate in donation or pickup workflows, follow the instructions and eligibility rules actually shown. Pickup or rewards are not guaranteed unless confirmed. Feature availability and reward terms may change; Rewards or pickup are available only when confirmed by the relevant in-app workflow.',
      ),

      _section(
        '12. Intellectual property',
        'You must own or have permission to use product photos, portfolio work, designs, certificates, descriptions and other material you upload. You allow EcoLoop to host and display content as reasonably necessary to operate public profiles, listings and selected features. Ownership or licensing of commissioned custom work should be agreed with the customer before work begins; Agree with the customer in writing on ownership or licensing of commissioned work before work begins, subject to applicable law.',
      ),

      _section(
        '13. Moderation and suspension',
        'EcoLoop may remove listings or restrict accounts where reasonably necessary to address unlawful, deceptive, unsafe or abusive activity, subject to applicable law. If you believe a moderation or account decision is incorrect, contact ecoloopp2026@gmail.com with the relevant listing or account reference.',
      ),

      _section(
        '14. Privacy and account closure',
        'The Privacy Policy describes known data uses and unresolved implementation issues. Current account closure may deactivate an account and revoke sessions without erasing all orders, reviews, analytics, custom-service records or stored media. Do not promise complete erasure. Some records and media may be retained after account closure for transaction, security, backup or legal reasons, subject to applicable law.',
      ),

      _section(
        '15. Platform availability and legal compliance',
        'The service may be interrupted or changed. You remain responsible for applicable laws relevant to your goods, services, business, tax and consumer obligations. Liability limits, indemnities, dispute forum and governing-law wording require review by Indian counsel and must not override mandatory rights.',
      ),

      _section(
        '16. Contact and grievances',
        'For a complaint or grievance, email ecoloopp2026@gmail.com with the subject “EcoLoop Grievance” and include the relevant order or account reference. Do not send passwords, OTPs or payment credentials. The EcoLoop team is the current contact point; the operator should publish any legally required grievance-officer designation and postal address before commercial launch.',
      ),

      _section(
        '17. Changes',
        'This version was reviewed on 24 October 2026. Material changes may be notified through the app or another reasonable channel where required by law.',
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
          'Terms & Conditions',
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
                      Icons.description_outlined,
                      color: ArtistColors.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please read these terms carefully.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ArtistColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Policy information is provided for transparency. Contact EcoLoop support with questions about a specific transaction or your rights under applicable law.',
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
                    'Support: ecoloopp2026@gmail.com\n'
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
