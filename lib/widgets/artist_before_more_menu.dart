import 'package:flutter/material.dart';

import '../screens/common/artist/about_ecoloop.dart';
import '../screens/common/artist/faq.dart';
import '../screens/common/artist/help_support.dart';
import '../screens/common/artist/how_it_works.dart';
import '../screens/common/artist/terms_conditions.dart';

class ArtistBeforeMoreMenu extends StatelessWidget {
  const ArtistBeforeMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More',

      onSelected: (value) {
        switch (value) {
          case 'about':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistAboutEcoLoop()),
            );
            break;

          case 'faq':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistFAQ()),
            );
            break;

          case 'help':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ArtistHelpSupportScreen(),
              ),
            );
            break;

          case 'how_it_works':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistHowItWorks()),
            );
            break;

          case 'terms':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistTermsConditions()),
            );
            break;
        }
      },

      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.eco_outlined),
              SizedBox(width: 12),
              Text('About EcoLoop'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'faq',
          child: Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 12),
              Text('FAQ'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.support_agent_outlined),
              SizedBox(width: 12),
              Text('Help & Support'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'how_it_works',
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text('How It Works!'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'terms',
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text('Terms & Conditions'),
            ],
          ),
        ),
      ],
    );
  }
}
