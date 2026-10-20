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
        'These terms apply to EcoLoop ReMaker features, including public profiles, portfolios, product listings, orders, followers, reviews, analytics and custom-service responses. EcoLoop facilitates platform features and is not automatically a party to every sale or commissioned-work agreement. Formal legal entity details and business address are Pending.',
      ),

      _section(
        '2. Acceptance and eligibility',
        'Using ReMaker features means you agree to these terms and the Privacy Policy. The minimum permitted age is Pending and must be decided before launch. You must have the legal capacity and permissions needed to sell goods or provide services.',
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
        'Current payment arrangements are COD and/or offline only; online payment gateway processing is not active. Confirm the order and agreed payment arrangement before fulfilment. Keep customer information confidential and use contact or address details only as needed for the transaction. Delivery responsibility, delivery fees, cancellation windows, returns, refunds and damaged or missing item handling are Pending where not specified by the actual workflow.',
      ),

      _section(
        '7. Earnings and fees',
        'Earnings or analytics displayed in the app are system records or summaries and do not necessarily mean money has been collected or settled by EcoLoop. Commission, platform fees, payout methods, settlement timing, taxes and accounting documentation are Pending unless explicitly disclosed and supported by the live process. Do not assume online payment processing or automatic payouts are available.',
      ),

      _section(
        '8. Custom-service proposals',
        'When responding to a custom-service request, describe the scope, deliverables, price, timeline, revisions, materials, delivery or collection arrangements and acceptance conditions clearly. Do not accept work you cannot reasonably complete. Rules for deposits, cancellation, refunds, ownership or licensing, late work and disputes are Pending unless agreed in writing by both parties and consistent with law. Use customer reference images only for the requested purpose and do not republish them without permission.',
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
        'If you participate in donation or pickup workflows, follow the instructions and eligibility rules actually shown. Pickup or rewards are not guaranteed unless confirmed. Feature availability and reward terms may change; details not implemented or specified are Pending.',
      ),

      _section(
        '12. Intellectual property',
        'You must own or have permission to use product photos, portfolio work, designs, certificates, descriptions and other material you upload. You allow EcoLoop to host and display content as reasonably necessary to operate public profiles, listings and selected features. Ownership or licensing of commissioned custom work should be agreed with the customer before work begins; a universal ownership rule is Pending legal review.',
      ),

      _section(
        '13. Moderation and suspension',
        'EcoLoop may remove listings or restrict accounts where reasonably necessary to address unlawful, deceptive, unsafe or abusive activity, subject to applicable law. A formal notice and appeal process is Pending and should be documented before launch.',
      ),

      _section(
        '14. Privacy and account closure',
        'The Privacy Policy describes known data uses and unresolved implementation issues. Current account closure may deactivate an account and revoke sessions without erasing all orders, reviews, analytics, custom-service records or stored media. Do not promise complete erasure. Retention and deletion timelines are Pending.',
      ),

      _section(
        '15. Platform availability and legal compliance',
        'The service may be interrupted or changed. You remain responsible for applicable laws relevant to your goods, services, business, tax and consumer obligations. Liability limits, indemnities, dispute forum and governing-law wording require review by Indian counsel and must not override mandatory rights.',
      ),

      _section(
        '16. Contact and grievances',
        'Contact ecoloopp2026@gmail.com for support, account, order or grievance issues. A designated grievance officer’s details, postal address, response deadlines and escalation procedure are Pending.',
      ),

      _section(
        '17. Changes',
        'The effective date and process for notifying ReMakers of material changes are Pending. The published policy should display the actual current version and effective date.',
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
                            'Draft for review. Minimum age, formal operator details, grievance procedure and transaction rules remain Pending.',
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
                    'Draft — not yet legally approved.',
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
