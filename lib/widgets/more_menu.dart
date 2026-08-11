import 'package:flutter/material.dart';

import '../screens/common/about_ecoloop.dart';
import '../screens/common/faq.dart';
import '../screens/common/help_support.dart';
import '../screens/common/terms_conditions.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: "More",
      onSelected: (value) {
        switch (value) {
          case "about":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AboutEcoLoop(),
              ),
            );
            break;

          case "faq":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FAQPage(),
              ),
            );
            break;

          case "help":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpSupport(),
              ),
            );
            break;

          case "terms":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsConditions(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: "about",
          child: Row(
            children: [
              Icon(Icons.eco_outlined),
              SizedBox(width: 12),
              Text("About EcoLoop"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "faq",
          child: Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 12),
              Text("FAQ"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "help",
          child: Row(
            children: [
              Icon(Icons.support_agent_outlined),
              SizedBox(width: 12),
              Text("Help & Support"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "terms",
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text("Terms & Conditions"),
            ],
          ),
        ),
      ],
    );
  }
}