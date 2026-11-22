import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/connection_service.dart';

const _connectionNavy = Color(0xFF10243B);
const _connectionTeal = Color(0xFF00999D);

// Shows messages and connection requests for the signed-in user.
class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({
    super.key,
    this.employerView = false,
    this.trainerView = false,
  });

  final bool employerView;
  final bool trainerView;

  @override
  Widget build(BuildContext context) {
    // Ask the user to sign in before showing private connection details.
    if (!ConnectionService.isSignedIn) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign in with a registered account to view requests and messages.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    final currentUid = ConnectionService.currentUserId!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        Text(
          employerView
              ? 'Applications & messages'
              : trainerView
              ? 'Learner enrollments & messages'
              : 'Messages & requests',
          style: TextStyle(
            color: _connectionNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          employerView
              ? 'Review worker requests and manage conversations.'
              : trainerView
              ? 'Review course enrollments and message accepted learners.'
              : 'Review requests and continue accepted conversations.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: employerView
              ? 'Incoming applications & requests'
              : trainerView
              ? 'Course enrollments'
              : 'Incoming requests',
        ),
        const SizedBox(height: 8),
        _RequestList(incoming: true, currentUid: currentUid),
        const SizedBox(height: 20),
        _SectionHeader(
          title: employerView || trainerView
              ? 'Requests sent'
              : 'Requests you sent',
        ),
        const SizedBox(height: 8),
        _RequestList(incoming: false, currentUid: currentUid),
      ],
    );
  }
}

// Shows either incoming requests or requests sent by the user.
class ConnectionRequestsPage extends StatelessWidget {
  const ConnectionRequestsPage({super.key, required this.incoming});

  final bool incoming;

  @override
  Widget build(BuildContext context) {
    if (!ConnectionService.isSignedIn) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign in with a registered account to view connection requests.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        Text(
          incoming ? 'Incoming requests' : 'Requests you sent',
          style: const TextStyle(
            color: Color(0xFF10243B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Requests and their latest approval status.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 14),
        _RequestList(
          incoming: incoming,
          currentUid: ConnectionService.currentUserId!,
        ),
      ],
    );
  }
}

// Loads requests from Firestore and shows loading, error, or empty states.
class _RequestList extends StatelessWidget {
  const _RequestList({required this.incoming, required this.currentUid});

  final bool incoming;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectionRequest>>(
      stream: ConnectionService.watchRequests(incoming: incoming),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatusPanel(
            icon: Icons.error_outline,
            message: 'Could not load requests: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return _StatusPanel(
            icon: Icons.inbox_outlined,
            message: incoming
                ? 'No requests received yet.'
                : 'You have not sent any requests yet.',
          );
        }
        return Column(
          children: [
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ConnectionRequestCard(
                  request: request,
                  incoming: incoming,
                  currentUid: currentUid,
                ),
              ),
          ],
        );
      },
    );
  }
}

// Shows one request and the actions available for its current status.
class _ConnectionRequestCard extends StatelessWidget {
  const _ConnectionRequestCard({
    required this.request,
    required this.incoming,
    required this.currentUid,
  });

  final ConnectionRequest request;
  final bool incoming;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                color: _connectionTeal,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    color: _connectionNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RequestStatus(status: request.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${incoming ? request.requesterName : request.ownerName} · '
            '${_typeLabel(request.type)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          if (request.paymentMethod != null) ...[
            const SizedBox(height: 7),
            _RequestPaymentSummary(request: request),
          ],
          if (request.status == 'pending' && incoming) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, accept: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, accept: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _connectionTeal,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (incoming &&
              request.status == 'accepted' &&
              (request.paymentStatus == 'awaiting_cash' ||
                  request.paymentStatus == 'awaiting_bank_transfer')) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmOfflinePayment(context),
                icon: const Icon(Icons.verified_outlined, size: 17),
                label: const Text('Confirm offline payment received'),
              ),
            ),
          ],
          if (request.status == 'accepted') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ConversationPage(request: request),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: const Text('Open conversation'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Sends the owner's decision to Firestore.
  Future<void> _respond(BuildContext context, {required bool accept}) async {
    try {
      await ConnectionService.respondToRequest(request, accept: accept);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Request accepted.' : 'Request declined.'),
          ),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) _showError(context, error.message ?? error.code);
    } catch (error) {
      if (context.mounted) _showError(context, error.toString());
    }
  }

  Future<void> _confirmOfflinePayment(BuildContext context) async {
    try {
      await ConnectionService.confirmOfflinePayment(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline payment marked as received.')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) _showError(context, error.message ?? error.code);
    } catch (error) {
      if (context.mounted) _showError(context, error.toString());
    }
  }
}

class _RequestPaymentSummary extends StatelessWidget {
  const _RequestPaymentSummary({required this.request});

  final ConnectionRequest request;

  @override
  Widget build(BuildContext context) {
    final method = switch (request.paymentMethod) {
      'bkash_demo' => 'bKash demo',
      'nagad_demo' => 'Nagad demo',
      'cash' => 'Cash',
      'bank_transfer' => 'Bank transfer',
      _ => 'Payment',
    };
    final status = switch (request.paymentStatus) {
      'simulated' => 'simulation only · not charged',
      'awaiting_cash' => 'awaiting cash confirmation',
      'awaiting_bank_transfer' => 'awaiting bank confirmation',
      'confirmed_offline' => 'recipient confirmed receipt',
      _ => 'status unavailable',
    };
    final amount = request.amountBdt == null
        ? ''
        : ' · ৳${_formatPaymentAmount(request.amountBdt!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: _connectionTeal,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$method$amount · $status',
              style: const TextStyle(
                color: _connectionNavy,
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPaymentAmount(int amount) {
  return amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

// Shows the live messages for one accepted connection.
class _ConversationPage extends StatefulWidget {
  const _ConversationPage({required this.request});

  final ConnectionRequest request;

  @override
  State<_ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<_ConversationPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Sends the typed message and clears the field when it succeeds.
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ConnectionService.sendMessage(widget.request, text);
      _controller.clear();
    } on FirebaseException catch (error) {
      if (mounted) _showError(context, error.message ?? error.code);
    } catch (error) {
      if (mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ConnectionService.currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.otherPartyName(currentUid ?? '')),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ConnectionMessage>>(
              stream: ConnectionService.watchMessages(widget.request.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load messages: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Connection accepted. Start the conversation.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderUid == currentUid;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFFE5F7F4)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(message.text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a heading above a group of connection details.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFF10243B),
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  );
}

// Shows a reusable loading, error, or empty-state message.
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a request status with a matching color.
class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' => const Color(0xFF008A68),
      'rejected' => const Color(0xFFB54747),
      _ => const Color(0xFFBA7600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Converts the stored request type into a readable label.
String _typeLabel(String type) => switch (type) {
  'course' => 'Course enrollment',
  'job' => 'Job application',
  _ => 'Service request',
};

// Shows an error message at the bottom of the screen.
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
