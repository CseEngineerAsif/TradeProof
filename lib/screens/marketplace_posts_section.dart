import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/connection_service.dart';
import 'course_checkout_page.dart';

// Shows posts from connected TradeProof accounts that can be requested.
class MarketplacePostsSection extends StatelessWidget {
  const MarketplacePostsSection({super.key, this.type});

  final String? type;

  static const _teal = Color(0xFF00999D);

  @override
  Widget build(BuildContext context) {
    // Listen for published posts and show the correct loading or error state.
    if (Firebase.apps.isEmpty) {
      return _notice(
        'Sign in to browse posts from connected TradeProof accounts.',
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return _notice(
        'Sign in to browse posts from connected TradeProof accounts.',
      );
    }
    return StreamBuilder<List<MarketplacePost>>(
      stream: ConnectionService.watchPosts(type: type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _notice(
            'Marketplace posts could not be loaded: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final posts = snapshot.data!;
        final otherPosts = posts.where((post) => post.ownerUid != currentUid);
        final ownPosts = posts.where((post) => post.ownerUid == currentUid);
        final visiblePosts = [...otherPosts, ...ownPosts];
        if (visiblePosts.isEmpty) {
          return _notice(
            'No account posts yet. Published jobs, courses and services will appear here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.public_outlined, color: _teal, size: 15),
                SizedBox(width: 6),
                Text(
                  'Posts from TradeProof accounts',
                  style: TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final post in visiblePosts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MarketplacePostCard(post: post, currentUid: currentUid),
              ),
          ],
        );
      },
    );
  }

  Widget _notice(String message) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE4EC)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
    ),
  );
}

// Each card shows one post and its request button.
// Shows one marketplace post and lets the user send a request.
class _MarketplacePostCard extends StatefulWidget {
  const _MarketplacePostCard({required this.post, required this.currentUid});

  final MarketplacePost post;
  final String? currentUid;

  @override
  State<_MarketplacePostCard> createState() => _MarketplacePostCardState();
}

class _MarketplacePostCardState extends State<_MarketplacePostCard> {
  bool _sending = false;

  // Sends a request to the owner of this marketplace post.
  Future<void> _request() async {
    // Send a connection request for this post.
    setState(() => _sending = true);
    try {
      await ConnectionService.requestPost(widget.post);
      if (mounted) _showMessage('Request sent to ${widget.post.ownerName}.');
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkout() async {
    setState(() => _sending = true);
    try {
      await openCourseCheckout(context, widget.post);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isOwnPost = widget.currentUid == widget.post.ownerUid;
    final actionLabel = widget.post.actionLabel;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _postIcon(widget.post.type),
                color: MarketplacePostsSection._teal,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.post.title,
                  style: const TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isOwnPost)
                const Text(
                  'YOUR POST',
                  style: TextStyle(
                    color: Color(0xFF008A68),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.post.category} · ${widget.post.ownerName} '
            '(${widget.post.ownerRole})',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
          ),
          const SizedBox(height: 6),
          Text(
            widget.post.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 10,
              height: 1.35,
            ),
          ),
          if (!isOwnPost) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 34,
                child: FilledButton.icon(
                  onPressed: _sending
                      ? null
                      : widget.post.type == 'course'
                      ? _checkout
                      : _request,
                  icon: _sending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 14),
                  label: Text(
                    _sending
                        ? 'Opening...'
                        : widget.post.type == 'course'
                        ? 'Enroll · checkout'
                        : actionLabel,
                    style: const TextStyle(fontSize: 9),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00999D),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _postIcon(String type) => switch (type) {
  'course' => Icons.school_outlined,
  'job' => Icons.work_outline,
  _ => Icons.handyman_outlined,
};
