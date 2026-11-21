import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/connection_service.dart';

class EmployerWorkerSearchTab extends StatefulWidget {
  const EmployerWorkerSearchTab({
    super.key,
    required this.initialQuery,
    required this.onQueryChanged,
  });

  final String initialQuery;
  final ValueChanged<String> onQueryChanged;

  @override
  State<EmployerWorkerSearchTab> createState() =>
      _EmployerWorkerSearchTabState();
}

class _EmployerWorkerSearchTabState extends State<EmployerWorkerSearchTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant EmployerWorkerSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _searchController.text != widget.initialQuery) {
      _searchController.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ConnectionService.isSignedIn) {
      return const _SearchNotice(
        message: 'Sign in to search and contact TradeProof workers.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        const Text(
          'Find workers',
          style: TextStyle(
            color: Color(0xFF10243B),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Search published tradesperson profiles and send a service request.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: widget.onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Name, trade, skill, or credential',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      widget.onQueryChanged('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<MarketplacePost>>(
          stream: ConnectionService.watchPosts(type: 'service'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SearchNotice(
                message: 'Workers could not be loaded: ${snapshot.error}',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final currentUid = ConnectionService.currentUserId!;
            final query = _searchController.text.trim().toLowerCase();
            final workers = snapshot.data!.where((post) {
              if (post.ownerUid == currentUid ||
                  !post.ownerRole.toLowerCase().contains('trade')) {
                return false;
              }
              return query.isEmpty ||
                  '${post.ownerName} ${post.ownerRole} ${post.title} '
                          '${post.category} ${post.description}'
                      .toLowerCase()
                      .contains(query);
            }).toList();
            if (workers.isEmpty) {
              return _SearchNotice(
                message: query.isEmpty
                    ? 'No worker profiles are published yet.'
                    : 'No workers match "$query".',
              );
            }
            return Column(
              children: [
                for (final worker in workers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _WorkerPostCard(post: worker),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WorkerPostCard extends StatefulWidget {
  const _WorkerPostCard({required this.post});

  final MarketplacePost post;

  @override
  State<_WorkerPostCard> createState() => _WorkerPostCardState();
}

class _WorkerPostCardState extends State<_WorkerPostCard> {
  bool _sending = false;

  Future<void> _contactWorker() async {
    setState(() => _sending = true);
    try {
      await ConnectionService.requestPost(widget.post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${widget.post.ownerName}.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) _showError(error.message ?? error.code);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
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
              const CircleAvatar(
                backgroundColor: Color(0xFFE0F4F2),
                child: Icon(Icons.person_outline, color: Color(0xFF00999D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.ownerName,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${widget.post.ownerRole} · ${widget.post.category}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_outlined, color: Color(0xFF00999D)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            widget.post.title,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.post.description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _sending ? null : _contactWorker,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00999D),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.handshake_outlined, size: 17),
              label: Text(_sending ? 'Sending...' : 'Request service'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ),
    );
  }
}
