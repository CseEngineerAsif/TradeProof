import 'package:flutter/material.dart';

// Groups credentials by the type of proof they provide.
enum _CredentialCategory {
  tradeCerts('Trade Certs', 'Vocational', Icons.workspace_premium_outlined),
  courseCerts('Course Certs', 'Bootcamps', Icons.school_outlined),
  govtLicenses('Govt Licenses', 'Regulated', Icons.shield_outlined),
  skillProofs('Skill Proofs', 'Site Audits', Icons.fact_check_outlined);

  const _CredentialCategory(this.label, this.subtitle, this.icon);

  final String label;
  final String subtitle;
  final IconData icon;
}

// Stores the details displayed for one certificate or license.
class _Credential {
  const _Credential({
    required this.title,
    required this.issuer,
    required this.id,
    required this.category,
    required this.date,
    required this.description,
    required this.verified,
  });

  final String title;
  final String issuer;
  final String id;
  final _CredentialCategory category;
  final String date;
  final String description;
  final bool verified;
}

// This page lists credentials and lets a worker upload new proof.
class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

// The selected category and credential list are stored in this state.
class _CredentialsPageState extends State<CredentialsPage> {
  _CredentialCategory? _selectedCategory;
  final List<_Credential> _credentials = _sampleCredentials();

  List<_Credential> get _visibleCredentials {
    // Show every credential when no category is selected.
    final selected = _selectedCategory;
    if (selected == null) return _credentials;
    return _credentials
        .where((credential) => credential.category == selected)
        .toList();
  }

  int _countFor(_CredentialCategory category) {
    return _credentials
        .where((credential) => credential.category == category)
        .length;
  }

  Future<void> _addCredential() async {
    // Open the form and add the new credential when it is submitted.
    final credential = await showDialog<_Credential>(
      context: context,
      builder: (_) => const _AddCredentialDialog(),
    );
    if (!mounted || credential == null) return;
    setState(() {
      _credentials.insert(0, credential);
      _selectedCategory = credential.category;
    });
  }

  void _showUnavailableMessage(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action is not connected in this demo yet.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Show the upload action, category filters, and matching credentials.
    final credentials = _visibleCredentials;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 20),
          children: [
            _LockerCard(onUpload: _addCredential),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: [
                  for (final category in _CredentialCategory.values)
                    _CategoryCard(
                      category: category,
                      count: _countFor(category),
                      selected: category == _selectedCategory,
                      onTap: () => setState(
                        () => _selectedCategory = category == _selectedCategory
                            ? null
                            : category,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (credentials.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No credentials in this category yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              for (final credential in credentials)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CredentialCard(
                    credential: credential,
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _CertificatePage(credential: credential),
                      ),
                    ),
                    onDownload: () => _showUnavailableMessage('Download'),
                    onShare: () => _showUnavailableMessage('Share'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// Top card with the compliance locker title and upload action.
// Shows the credential locker title and upload button.
class _LockerCard extends StatelessWidget {
  const _LockerCard({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FCFC),
                  border: Border.all(color: const Color(0xFFB7F0EA)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF00999D),
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compliance Locker & Credentials',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Verified trade certificates, course diplomas,...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add, size: 17),
              label: const Text(
                'Upload Document',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF008C95),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows one credential category and how many items it contains.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _CredentialCategory category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = {
      _CredentialCategory.tradeCerts: Color(0xFF5446FF),
      _CredentialCategory.courseCerts: Color(0xFF008DA3),
      _CredentialCategory.govtLicenses: Color(0xFFE78300),
      _CredentialCategory.skillProofs: Color(0xFF008B66),
    };
    const backgrounds = {
      _CredentialCategory.tradeCerts: Color(0xFFE9E9FF),
      _CredentialCategory.courseCerts: Color(0xFFE1FAFC),
      _CredentialCategory.govtLicenses: Color(0xFFFFF2CC),
      _CredentialCategory.skillProofs: Color(0xFFE0FBF0),
    };
    final color = colors[category]!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : const Color(0xFFDCE4EC),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: backgrounds[category],
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(category.icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shows a credential summary and its available actions.
class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.credential,
    required this.onView,
    required this.onDownload,
    required this.onShare,
  });

  final _Credential credential;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final verifiedColor = credential.verified
        ? const Color(0xFF008C68)
        : const Color(0xFFE78300);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF5446FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${credential.issuer} · ${credential.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        credential.id,
                        style: const TextStyle(
                          color: Color(0xFF40536A),
                          fontFamily: 'monospace',
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1, color: Color(0xFFE6EBF0)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: credential.verified
                      ? const Color(0xFFE9FFF6)
                      : const Color(0xFFFFF5E5),
                  border: Border.all(
                    color: credential.verified
                        ? const Color(0xFF9BEBC9)
                        : const Color(0xFFFFD58B),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      credential.verified
                          ? Icons.circle
                          : Icons.hourglass_bottom,
                      size: 6,
                      color: verifiedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      credential.verified ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        color: verifiedColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 31,
                child: FilledButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text(
                    'View Document',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _CredentialIconButton(
                icon: Icons.download_outlined,
                onPressed: onDownload,
              ),
              const SizedBox(width: 4),
              _CredentialIconButton(
                icon: Icons.share_outlined,
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CredentialIconButton extends StatelessWidget {
  const _CredentialIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton.filled(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF0F4F7),
          foregroundColor: const Color(0xFF334155),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

// Shows the full details and certificate artwork for one credential.
class _CertificatePage extends StatelessWidget {
  const _CertificatePage({required this.credential});

  final _Credential credential;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: const Text('View Document'),
        backgroundColor: const Color(0xFFF3F5F8),
        foregroundColor: const Color(0xFF10243B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CertificateArtwork(credential: credential),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(
                credential.verified
                    ? Icons.verified_outlined
                    : Icons.pending_outlined,
                color: credential.verified
                    ? const Color(0xFF008C68)
                    : const Color(0xFFE78300),
              ),
              title: Text(
                credential.verified
                    ? 'TradeProof verified document'
                    : 'Awaiting document verification',
              ),
              subtitle: Text('Credential ID: ${credential.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

// Draws a decorative certificate using the credential details.
class _CertificateArtwork extends StatelessWidget {
  const _CertificateArtwork({required this.credential});

  final _Credential credential;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF07533F);
    return AspectRatio(
      aspectRatio: 0.76,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFA),
          border: Border.all(color: green, width: 1.5),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              child: _CertificateCorner(color: Color(0xFFFFA000)),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              child: RotatedBox(
                quarterTurns: 2,
                child: _CertificateCorner(color: Color(0xFF07533F)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    children: [
                      Text(
                        'C E R T I F I C A T E',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: green,
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'O F   A C H I E V E M E N T',
                        style: TextStyle(
                          color: Color(0xFF29364A),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Proudly Present To:',
                        style: TextStyle(
                          color: Color(0xFF52617A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        credential.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE2A600),
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        credential.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF35445B),
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Issued by ${credential.issuer}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF76859A),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CertificateSignature(
                        label: 'Director',
                        value: credential.issuer,
                      ),
                      _CertificateSignature(
                        label: 'Date',
                        value: credential.date,
                      ),
                    ],
                  ),
                  Text(
                    'Credential ID: ${credential.id}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7C8BA0),
                      fontFamily: 'monospace',
                      fontSize: 9,
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
}

class _CertificateCorner extends StatelessWidget {
  const _CertificateCorner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CornerClipper(),
      child: Container(width: 105, height: 90, color: color),
    );
  }
}

class _CornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CertificateSignature extends StatelessWidget {
  const _CertificateSignature({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Collects the details for a new credential record.
class _AddCredentialDialog extends StatefulWidget {
  const _AddCredentialDialog();

  @override
  State<_AddCredentialDialog> createState() => _AddCredentialDialogState();
}

class _AddCredentialDialogState extends State<_AddCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _idController = TextEditingController();
  _CredentialCategory _category = _CredentialCategory.tradeCerts;

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _submit() {
    // Validate the form and return the new credential to the page.
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _Credential(
        title: _titleController.text.trim(),
        issuer: _issuerController.text.trim(),
        id: _idController.text.trim(),
        category: _category,
        date: 'Pending review',
        description:
            'This credential has been added to the locker and is waiting '
            'for document verification.',
        verified: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Collect the credential name, category, issuer, and other details.
    return AlertDialog(
      title: const Text('Upload Credential'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Demo mode adds a credential record for review; document file upload is not connected yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 12),
              _CredentialInput(
                controller: _titleController,
                label: 'Credential name',
              ),
              _CredentialInput(
                controller: _issuerController,
                label: 'Issuing organization',
              ),
              _CredentialInput(
                controller: _idController,
                label: 'Credential ID',
              ),
              DropdownButtonFormField<_CredentialCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final category in _CredentialCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add for Review')),
      ],
    );
  }
}

// Reusable text field used in the credential form.
class _CredentialInput extends StatelessWidget {
  const _CredentialInput({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter $label.' : null,
      ),
    );
  }
}

List<_Credential> _sampleCredentials() {
  const categories = _CredentialCategory.values;
  const targets = [4, 5, 4, 5];
  const issuerByCategory = {
    _CredentialCategory.tradeCerts: 'City & Guilds of London Institute',
    _CredentialCategory.courseCerts: 'TradeProof Skills Academy',
    _CredentialCategory.govtLicenses: 'Bangladesh Technical Education Board',
    _CredentialCategory.skillProofs: 'TradeProof Site Audits',
  };
  const titlesByCategory = {
    _CredentialCategory.tradeCerts: [
      'Electrical Installation & Maintenance (Level 3)',
      'Advanced Electrical Installation Certificate',
      'Commercial Wiring & Safety Certificate',
      'Electrical Systems Maintenance Certificate',
    ],
    _CredentialCategory.courseCerts: [
      'National Skill Certificate in Electrical Works',
      'Smart Grid Installation Course Diploma',
      'Solar PV Installation Bootcamp',
      'Electrical Safety Refresher Course',
      'Workplace Compliance Essentials',
    ],
    _CredentialCategory.govtLicenses: [
      'Government Electrical Work License',
      'Electrical Contractor Registration',
      'Occupational Safety License',
      'Trade Practice License',
    ],
    _CredentialCategory.skillProofs: [
      'Commercial Site Safety Audit',
      'Electrical Panel Inspection Proof',
      'Residential Smart Grid Installation',
      'Workplace Risk Assessment',
      'Quality Installation Assessment',
    ],
  };

  final credentials = <_Credential>[];
  for (
    var categoryIndex = 0;
    categoryIndex < categories.length;
    categoryIndex++
  ) {
    final category = categories[categoryIndex];
    final titles = titlesByCategory[category]!;
    for (var index = 0; index < targets[categoryIndex]; index++) {
      final idNumber = 9843 + credentials.length * 137;
      credentials.add(
        _Credential(
          title: titles[index],
          issuer: issuerByCategory[category]!,
          id: 'TP-${category.name.substring(0, 3).toUpperCase()}-$idNumber',
          category: category,
          date: index == 0 ? 'Aug 20, 2023' : 'Mar 12, 2024',
          description:
              'Awarded for demonstrating verified skills, safe working '
              'practice, and successful completion of the required '
              'practical assessments.',
          verified: true,
        ),
      );
    }
  }
  return credentials;
}
