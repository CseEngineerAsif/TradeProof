import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/connection_service.dart';

class EmployerJobsTab extends StatefulWidget {
  const EmployerJobsTab({super.key});

  @override
  State<EmployerJobsTab> createState() => _EmployerJobsTabState();
}

class _EmployerJobsTabState extends State<EmployerJobsTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _requireL3 = true;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishJob() async {
    if (!_formKey.currentState!.validate() || _isPublishing) return;
    setState(() => _isPublishing = true);
    try {
      await ConnectionService.publishPost(
        type: 'job',
        title: _titleController.text,
        category: _categoryController.text,
        description:
            '${_descriptionController.text.trim()}\n\n'
            'Verification required: '
            '${_requireL3 ? 'Gold L3 Verification' : 'Standard L1 Compliance'}.',
      );
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      if (mounted) _showMessage('Job published for worker applications.');
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _closeJob(MarketplacePost job) async {
    try {
      await ConnectionService.closePost(job);
      if (mounted) _showMessage('Job post closed.');
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!ConnectionService.isSignedIn) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Sign in with an employer account to publish and manage jobs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        const Text(
          'Job posts',
          style: TextStyle(
            color: Color(0xFF10243B),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Publish opportunities for tradespeople to discover and apply to.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 15),
        _buildJobForm(),
        const SizedBox(height: 20),
        const Text(
          'Your published jobs',
          style: TextStyle(
            color: Color(0xFF10243B),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<MarketplacePost>>(
          stream: ConnectionService.watchMyPosts(type: 'job'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Notice(
                message: 'Could not load job posts: ${snapshot.error}',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final jobs = snapshot.data!;
            if (jobs.isEmpty) {
              return const _Notice(
                message: 'Your job posts will appear here after publishing.',
              );
            }
            return Column(
              children: [
                for (final job in jobs)
                  _JobCard(
                    job: job,
                    onClose: job.status == 'published'
                        ? () => _closeJob(job)
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a job',
              style: TextStyle(
                color: Color(0xFF10243B),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Job title',
                border: OutlineInputBorder(),
              ),
              validator: _requiredField,
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Trade category',
                border: OutlineInputBorder(),
              ),
              validator: _requiredField,
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Job description',
                border: OutlineInputBorder(),
              ),
              validator: _requiredField,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Require Gold L3 verification',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Switch(
                  value: _requireL3,
                  activeThumbColor: const Color(0xFF00999D),
                  onChanged: (value) => setState(() => _requireL3 = value),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isPublishing ? null : _publishJob,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00999D),
                ),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(_isPublishing ? 'Publishing...' : 'Publish job'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onClose});

  final MarketplacePost job;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, color: Color(0xFF00999D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: job.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            job.category,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            job.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          if (onClose != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: const Text('Close job'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'published';
    final color = isOpen ? const Color(0xFF008A68) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  border: Border.all(color: const Color(0xFFDCE4EC)),
  borderRadius: BorderRadius.circular(12),
);
