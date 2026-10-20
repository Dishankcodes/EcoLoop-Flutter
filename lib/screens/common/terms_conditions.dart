import 'package:flutter/material.dart';
import '../../app_theme/user/app_colors.dart';

class TermsConditions extends StatelessWidget {
  const TermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _section(
        '1. About EcoLoop',
        'EcoLoop is intended to help people discover, buy, sell and donate reusable items and connect with ReMakers offering creative or custom work. EcoLoop provides platform features and is not automatically the seller, buyer, donor, recipient, courier or maker in every transaction. Formal legal entity details and business address are Pending.',
      ),

      _section(
        '2. Acceptance and eligibility',
        'By accessing or using EcoLoop, you agree to these terms and the Privacy Policy. The minimum permitted age is Pending and must be decided before launch. Do not use the service if you are not legally permitted to enter into the relevant agreement.',
      ),

      _section(
        '3. Account and security',
        'Provide accurate information, protect your credentials and never share passwords, OTPs or session links. Contact support promptly if you suspect unauthorised access. You are responsible for activity through your account, subject to applicable law. Account recovery and email-change rules depend on the features actually available in the app.',
      ),

      _section(
        '4. Public profiles and content',
        'Profiles, product listings, portfolio content, images, descriptions, prices and reviews intended for public display may be visible to other users and the public. Do not publish private addresses, identity documents, confidential information or another person’s personal data without authority. Settings switches should not be treated as guarantees of privacy unless their server-side behaviour has been verified.',
      ),

      _section(
        '5. Product listings',
        'List only items you are entitled to sell or donate. Provide accurate descriptions, condition, images, category, quantity, price and availability. Do not list illegal, stolen, counterfeit, unsafe, misleading or otherwise prohibited goods. You are responsible for the accuracy and lawful ownership of your listings and for updating unavailable items.',
      ),

      _section(
        '6. Buying, orders and COD',
        'Review product and order details before placing an order. EcoLoop currently supports Cash on Delivery (COD) and/or offline payment arrangements only; online payment gateway processing is not active. Do not treat an order as paid until the agreed payment has actually been completed. Follow the payment and delivery information shown in the live checkout. Any unspecified payment or delivery rules are Pending.',
      ),

      _section(
        '7. Delivery, cancellations and disputes',
        'Order status and available cancellation options may depend on the current workflow and fulfilment status. A complete policy covering cancellations, returns, refunds, damaged items, missing items, non-delivery and disputes is Pending. Do not assume automatic refunds or guaranteed delivery unless the relevant process is implemented and disclosed. Contact support if a transaction issue cannot be resolved directly.',
      ),

      _section(
        '8. Donations and pickups',
        'Donation requests may be submitted through available app features. Acceptance, item eligibility, pickup availability, recipient selection, rewards and collection timing depend on the actual workflow. A pickup or reward is not guaranteed unless confirmed. Do not donate items you are not authorised to give away or items that are unsafe or prohibited.',
      ),

      _section(
        '9. Custom services',
        'You may submit a custom-service brief, budget and reference material and receive proposals from ReMakers. Before agreeing, review the scope, price, deliverables, timeline, revisions, delivery or collection arrangements and acceptance conditions. Ownership or licensing of commissioned work, deposits, cancellations, refunds, late delivery and dispute handling are Pending unless clearly agreed in writing by the parties and permitted by law. Upload only material you have permission to share.',
      ),

      _section(
        '10. Reviews, wishlists and follows',
        'Reviews must be honest, relevant and based on genuine experience. Fake reviews, review manipulation, harassment, impersonation and retaliation are prohibited. Wishlists and follows are platform features and may change as the service evolves. Public reviews or interactions may remain visible after account deactivation, subject to applicable law and the final retention policy.',
      ),

      _section(
        '11. Prohibited conduct',
        'Do not use EcoLoop for fraud, unlawful activity, harassment, threats, spam, unauthorised access, harmful scraping, order or reward manipulation, or infringement of intellectual-property or privacy rights. EcoLoop may investigate reports and restrict content or accounts where reasonably necessary, subject to applicable law. A formal appeal process is Pending.',
      ),

      _section(
        '12. Intellectual property',
        'You retain rights you have in content you upload. You allow EcoLoop to host, store, display and transmit that content as reasonably necessary to operate the features you use, including public profiles and listings. You must have the rights and permissions needed for uploaded photos, descriptions, designs and reference materials. The final content-licence and takedown terms require legal review.',
      ),

      _section(
        '13. Privacy and account closure',
        'The Privacy Policy describes known data uses and flags implementation gaps. Account deactivation may not erase all associated records or media. Do not treat account closure as complete deletion. Contact ecoloopp2026@gmail.com for a privacy or deletion request. Data-retention periods are Pending.',
      ),

      _section(
        '14. Availability and changes',
        'Features may be changed, interrupted or discontinued for maintenance, safety or operational reasons. EcoLoop does not guarantee uninterrupted availability. Nothing in these terms removes rights or remedies that cannot lawfully be excluded.',
      ),

      _section(
        '15. Legal review',
        'These draft terms are not a substitute for advice from an Indian lawyer. Liability limits, indemnities, dispute forum, governing-law wording, consumer rights, e-commerce disclosures and grievance deadlines require legal review and must not unlawfully restrict statutory rights.',
      ),

      _section(
        '16. Contact and grievances',
        'Contact ecoloopp2026@gmail.com for support, transaction concerns or grievances. The designated grievance officer, postal address, response deadlines and formal escalation process are Pending and must be confirmed before publication.',
      ),

      _section(
        '17. Updates',
        'EcoLoop may update these terms as the service changes, subject to applicable law. The effective date and method for notifying users of material changes are Pending. The published version should display the actual effective date.',
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
          'Terms & Conditions',
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
                      Icons.description_outlined,
                      color: AppColors.primary,
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Draft for review. Minimum age, formal operator details, grievance procedure and some transaction rules remain Pending.',
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
                    'Support: ecoloopp2026@gmail.com\n'
                    'Draft — not yet legally approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last reviewed: 20 October 2026',
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
