import 'package:flutter/material.dart';

// Groups a heading and its list of details for the trade details page.
class TradeDetailsSection {
  const TradeDetailsSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

// Shows the full information for one trade, course, or service.
class TradeDetailsPage extends StatelessWidget {
  const TradeDetailsPage({
    super.key,
    required this.title,
    required this.provider,
    required this.location,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.description,
    required this.sections,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String provider;
  final String location;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final String description;
  final List<TradeDetailsSection> sections;
  final String actionLabel;
  final VoidCallback? onAction;

  // Shows a message when the demo action has not been connected yet.
  void _showActionMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('This action is not connected in the demo yet.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _DetailsHeader(
              title: title,
              provider: provider,
              location: location,
            ),
            Expanded(
              // Keep the details scrollable on small screens.
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 9, 14, 16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/tradeproof_workers.png',
                      height: 136,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 136,
                        color: const Color(0xFFE0E8EE),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.handyman_outlined,
                          size: 42,
                          color: Color(0xFF009E9A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _DetailsMetrics(
                    primaryLabel: primaryLabel,
                    primaryValue: primaryValue,
                    secondaryLabel: secondaryLabel,
                    secondaryValue: secondaryValue,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Details',
                    style: TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final section in sections) ...[
                    _DetailsSectionCard(section: section),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        // Keep the main action button visible at the bottom of the page.
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onAction ?? () => _showActionMessage(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00999D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// Shows the back button and the selected trade's main information.
class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.title,
    required this.provider,
    required this.location,
  });

  final String title;
  final String provider;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1A2C),
      padding: const EdgeInsets.fromLTRB(4, 2, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Full Details',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF052D40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF2CC2AE),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF25B8AD),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF9BAABC),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9BAABC),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// Displays the two key values passed into the details page.
class _DetailsMetrics extends StatelessWidget {
  const _DetailsMetrics({
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
  });

  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: primaryLabel, value: primaryValue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Metric(
              label: secondaryLabel,
              value: secondaryValue,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

// Shows one label and value, aligned to either side.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF008C75),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// Shows a heading and checklist of information for one section.
class _DetailsSectionCard extends StatelessWidget {
  const _DetailsSectionCard({required this.section});

  final TradeDetailsSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00999D),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF008C75),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        height: 1.3,
                      ),
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
