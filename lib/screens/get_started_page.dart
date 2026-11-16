import 'package:flutter/material.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  // This color is used for the main action button.
  static const _teal = Color(0xFF008C96);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Use the available screen height to keep the page layout balanced.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                // Allow scrolling when the screen is too short for the content.
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 40
                      ? constraints.maxHeight - 40
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show the app name and its verification logo.
                    const _BrandHeader(),
                    const SizedBox(height: 28),
                    // Show an image related to trade workers.
                    const _TradeIllustration(),
                    const SizedBox(height: 31),
                    // Explain the main benefits of using TradeProof.
                    const Column(
                      children: [
                        _FeatureCard(
                          title: 'Prove Your Skills',
                          description:
                              'Digitize and authenticate your practical credentials and safety cards.',
                        ),
                        SizedBox(height: 7),
                        _FeatureCard(
                          title: 'Find Verified Workers',
                          description:
                              'Instant visual compliance audits for employers and contractors.',
                        ),
                        SizedBox(height: 7),
                        _FeatureCard(
                          title: 'Build Civic Trust',
                          description:
                              'Raise industry standards through direct proof of on-site competence.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const SizedBox(height: 37),
                    const SizedBox(height: 6),
                    // Open the dashboard when the user taps this button.
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: _teal.withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Builds the logo and app name shown at the top of the page.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF008C96),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26008C96),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TradeProof',
              style: TextStyle(
                color: Color(0xFF101B2D),
                fontSize: 19,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Verified Skills. Trusted Trades.',
              style: TextStyle(
                color: Color(0xFF007D91),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Shows one benefit with a check icon, title, and description.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 71),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF294765)),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFF008F81),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Displays the workers image while keeping a fixed shape.
class _TradeIllustration extends StatelessWidget {
  const _TradeIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.49,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset('assets/tradeproof_workers.png', fit: BoxFit.cover),
      ),
    );
  }
}
