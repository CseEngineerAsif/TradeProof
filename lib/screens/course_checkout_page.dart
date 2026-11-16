import 'package:flutter/material.dart';

import '../services/connection_service.dart';

const _checkoutNavy = Color(0xFF10243B);
const _checkoutTeal = Color(0xFF00999D);
const _checkoutMuted = Color(0xFF64748B);

Future<bool?> openCourseCheckoutForTitle(
  BuildContext context,
  String title,
) async {
  final post = await ConnectionService.findPublishedCourseByTitle(title);
  if (!context.mounted) return null;
  return openCourseCheckout(context, post);
}

Future<bool?> openCourseCheckout(BuildContext context, MarketplacePost course) {
  if (course.priceBdt == null || course.priceBdt! <= 0) {
    throw StateError(
      'The course fee is not set up for checkout. Ask the trainer to update the course.',
    );
  }
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      pageBuilder: (_, _, _) => CourseCheckoutPage(course: course),
      transitionsBuilder: (_, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(slide),
            child: child,
          ),
        );
      },
    ),
  );
}

class CourseCheckoutPage extends StatefulWidget {
  const CourseCheckoutPage({super.key, required this.course});

  final MarketplacePost course;

  @override
  State<CourseCheckoutPage> createState() => _CourseCheckoutPageState();
}

class _CourseCheckoutPageState extends State<CourseCheckoutPage> {
  String? _selectedMethod;
  bool _submitting = false;
  bool _completed = false;

  int get _amountBdt => widget.course.priceBdt!;

  Future<void> _continue() async {
    final method = _selectedMethod;
    if (method == null || _submitting) return;
    if (method == 'bkash_demo' || method == 'nagad_demo') {
      final success = await Navigator.of(context).push<bool>(
        PageRouteBuilder<bool>(
          pageBuilder: (_, _, _) => _ProviderDemoPage(method: method),
          transitionsBuilder: (_, animation, _, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(slide),
                child: child,
              ),
            );
          },
        ),
      );
      if (success == true) {
        await _saveRequest(method, 'simulated');
      }
      return;
    }

    await _saveRequest(
      method,
      method == 'cash' ? 'awaiting_cash' : 'awaiting_bank_transfer',
    );
  }

  Future<void> _saveRequest(String method, String paymentStatus) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ConnectionService.requestPost(
        widget.course,
        paymentMethod: method,
        paymentStatus: paymentStatus,
      );
      if (mounted) setState(() => _completed = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F8),
        foregroundColor: _checkoutNavy,
        title: const Text('Course checkout'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _completed ? _buildConfirmation() : _buildCheckout(),
        ),
      ),
    );
  }

  Widget _buildCheckout() {
    return ListView(
      key: const ValueKey('checkout'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _orderSummary(),
        const SizedBox(height: 17),
        const Text(
          'Choose payment method',
          style: TextStyle(
            color: _checkoutNavy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        for (final option in _paymentOptions) ...[
          _PaymentMethodTile(
            option: option,
            selected: _selectedMethod == option.id,
            onTap: () => setState(() => _selectedMethod = option.id),
          ),
          const SizedBox(height: 8),
        ],
        if (_selectedMethod == 'cash' || _selectedMethod == 'bank_transfer')
          _offlineInstructions(_selectedMethod!),
        const SizedBox(height: 13),
        _prototypeNotice(),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _selectedMethod == null || _submitting
                ? null
                : _continue,
            style: FilledButton.styleFrom(
              backgroundColor: _checkoutTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _continueLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  String get _continueLabel => switch (_selectedMethod) {
    'bkash_demo' => 'Continue to bKash',
    'nagad_demo' => 'Continue to Nagad',
    'cash' || 'bank_transfer' => 'Send enrollment request',
    _ => 'Choose a payment method',
  };

  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENROLLMENT SUMMARY',
            style: TextStyle(
              color: _checkoutMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.title,
            style: const TextStyle(
              color: _checkoutNavy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Course by ${widget.course.ownerName}',
            style: const TextStyle(color: _checkoutMuted, fontSize: 11),
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total due',
                  style: TextStyle(
                    color: _checkoutNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatTaka(_amountBdt),
                style: const TextStyle(
                  color: _checkoutNavy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offlineInstructions(String method) {
    final isCash = method == 'cash';
    return Container(
      key: ValueKey(method),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFB6DED5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCash ? Icons.payments_outlined : Icons.account_balance_outlined,
            color: _checkoutTeal,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isCash
                  ? 'Pay the trainer in person after they accept your enrollment. Ask them to confirm receipt in TradeProof.'
                  : 'Ask the trainer for verified bank details after they accept. Transfer only to details confirmed in TradeProof.',
              style: const TextStyle(
                color: _checkoutNavy,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prototypeNotice() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF9A5B00), size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payment preview only. Online methods are simulated; no money is charged. Cash and bank transfers are not verified in the app.',
              style: TextStyle(
                color: Color(0xFF6D4A13),
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    final isSimulated =
        _selectedMethod == 'bkash_demo' || _selectedMethod == 'nagad_demo';
    return Center(
      key: const ValueKey('confirmation'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.65, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF008A68),
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSimulated ? 'Demo checkout complete' : 'Request sent',
              style: const TextStyle(
                color: _checkoutNavy,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSimulated
                  ? 'No money was charged. Your enrollment request is waiting for the course owner.'
                  : 'Your enrollment request is waiting for the course owner. Coordinate the offline payment after acceptance.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _checkoutMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.course.title}\n${_formatTaka(_amountBdt)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _checkoutNavy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _checkoutTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderDemoPage extends StatelessWidget {
  const _ProviderDemoPage({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isBkash = method == 'bkash_demo';
    final provider = isBkash ? 'bKash' : 'Nagad';
    final brandColor = isBkash
        ? const Color(0xFFD12053)
        : const Color(0xFFEF6C00);
    final accent = isBkash ? const Color(0xFFFFEEF3) : const Color(0xFFFFF3E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _checkoutNavy,
        title: const Text('Secure checkout preview'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: brandColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                provider,
                style: TextStyle(
                  color: brandColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Gateway-style preview',
                style: TextStyle(
                  color: _checkoutNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is a TradeProof demo screen, not the real provider gateway. No phone number, PIN or OTP is needed, and no transaction will be made.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _checkoutMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: _checkoutTeal, size: 19),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Never share your wallet PIN or one-time password in a demo app.',
                        style: TextStyle(
                          color: _checkoutNavy,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simulate demo payment'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.brand,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? brand;
}

const _paymentOptions = <_PaymentMethod>[
  _PaymentMethod(
    id: 'bkash_demo',
    title: 'bKash',
    subtitle: 'Mobile wallet · Demo only',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFFD12053),
    brand: 'bK',
  ),
  _PaymentMethod(
    id: 'nagad_demo',
    title: 'Nagad',
    subtitle: 'Mobile wallet · Demo only',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFFEF6C00),
    brand: 'N',
  ),
  _PaymentMethod(
    id: 'cash',
    title: 'Cash',
    subtitle: 'Pay the trainer in person',
    icon: Icons.payments_outlined,
    color: Color(0xFF008A68),
  ),
  _PaymentMethod(
    id: 'bank_transfer',
    title: 'Bank transfer',
    subtitle: 'Arrange verified details with the trainer',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF3367A6),
  ),
];

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF7F6) : Colors.white,
        border: Border.all(
          color: selected ? _checkoutTeal : const Color(0xFFDCE4EC),
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: option.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: option.brand == null
                      ? Icon(option.icon, color: option.color, size: 21)
                      : Text(
                          option.brand!,
                          style: TextStyle(
                            color: option.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          color: _checkoutNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        style: const TextStyle(
                          color: _checkoutMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? _checkoutTeal : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTaka(int amount) {
  final digits = amount.toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '৳$formatted';
}
