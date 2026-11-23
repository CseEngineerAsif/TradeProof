import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/auth_service.dart';
import 'account_status_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.draft});

  final AccountApplication? draft;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  static const _roles = <_AccountRole>[
    _AccountRole(
      'Tradesperson',
      'Show verified skills, licenses and work history.',
      Icons.handyman_outlined,
    ),
    _AccountRole(
      'Employer / Contractor',
      'Find skilled people and manage projects.',
      Icons.business_outlined,
    ),
    _AccountRole(
      'Trainer / Assessor',
      'Share courses and verify practical skills.',
      Icons.school_outlined,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _tradeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _historyController = TextEditingController();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  final _registrationController = TextEditingController();
  final _hiringNeedsController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _certificationsController = TextEditingController();

  int _selectedRole = 0;
  int _step = 0;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  PlatformFile? _cvFile;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft == null) return;

    _step = 1;
    _acceptedTerms = true;
    _nameController.text = draft.fullName;
    _emailController.text = draft.email;
    final details = draft.details;
    String value(String key) => details[key]?.toString() ?? '';
    _phoneController.text = value('phone');
    _locationController.text = value('location');
    _tradeController.text = value('trade');
    _experienceController.text = value('experienceYears');
    _qualificationController.text = value('qualifications');
    _historyController.text = value('workExperience');
    _companyController.text = value('companyName');
    _industryController.text = value('industry');
    _registrationController.text = value('registrationNumber');
    _hiringNeedsController.text = value('hiringNeeds');
    _specialtyController.text = value('specialty');
    _certificationsController.text = value('certifications');
    final roleIndex = _roles.indexWhere((role) => role.title == draft.role);
    if (roleIndex >= 0) _selectedRole = roleIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _tradeController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    _historyController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    _registrationController.dispose();
    _hiringNeedsController.dispose();
    _specialtyController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  String get _role => _roles[_selectedRole].title;

  void _continueToApplication() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showMessage('Agree to the terms and identity verification to continue.');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _pickCv() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      if (file == null) return;

      final fileSize = await file.length();
      if (fileSize == null) {
        _showMessage('Could not read the selected document size.');
        return;
      }
      if (fileSize >= 10 * 1024 * 1024) {
        _showMessage('Choose a document smaller than 10 MB.');
        return;
      }
      setState(() => _cvFile = file);
    } catch (error) {
      _showMessage('Could not select the document: $error');
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.createAccount(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        applicationDetails: _applicationDetails(),
        cvBytes: _cvFile == null ? null : await _cvFile!.readAsBytes(),
        cvFileName: _cvFile?.name ?? widget.draft?.cvFileName,
        existingCvPath: widget.draft?.cvPath,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AccountStatusPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(authErrorMessage(error));
    } on FirebaseException catch (error) {
      _showMessage(authErrorMessage(error));
    } catch (error) {
      _showMessage(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _applicationDetails() {
    final details = <String, dynamic>{
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
    };
    switch (_role) {
      case 'Tradesperson':
        details.addAll({
          'trade': _tradeController.text.trim(),
          'experienceYears': _experienceController.text.trim(),
          'qualifications': _qualificationController.text.trim(),
          'workExperience': _historyController.text.trim(),
        });
      case 'Employer / Contractor':
        details.addAll({
          'companyName': _companyController.text.trim(),
          'industry': _industryController.text.trim(),
          'registrationNumber': _registrationController.text.trim(),
          'hiringNeeds': _hiringNeedsController.text.trim(),
          'workExperience': _historyController.text.trim(),
        });
      case 'Trainer / Assessor':
        details.addAll({
          'specialty': _specialtyController.text.trim(),
          'experienceYears': _experienceController.text.trim(),
          'certifications': _certificationsController.text.trim(),
          'workExperience': _historyController.text.trim(),
        });
    }
    return details;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10243B),
        title: const Text('Create TradeProof account'),
        leading: IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_step == 1) {
                    setState(() => _step = 0);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _stepIndicator(),
              const SizedBox(height: 18),
              if (_step == 0) ..._buildAccountDetails(),
              if (_step == 1) ..._buildApplicationDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _step == 0 ? 'Create your account' : 'Professional application',
          style: const TextStyle(
            color: Color(0xFF10243B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _step == 0
              ? 'Step 1 of 2 · Choose your professional account'
              : 'Step 2 of 2 · Your application is reviewed before activation',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: _step == 0 ? 0.5 : 1,
            minHeight: 5,
            color: const Color(0xFF009B9D),
            backgroundColor: const Color(0xFFDCE4EC),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAccountDetails() {
    return [
      ...List.generate(_roles.length, (index) {
        final role = _roles[index];
        final selected = index == _selectedRole;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: _isLoading
                ? null
                : () => setState(() => _selectedRole = index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF009E9A)
                      : const Color(0xFFE0E6EE),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    role.icon,
                    color: selected
                        ? const Color(0xFF009E9A)
                        : const Color(0xFF94A7C1),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            color: Color(0xFF10243B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          role.description,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF009E9A),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 4),
      _field(
        controller: _nameController,
        label: 'Full name',
        validator: _requiredValidator,
        textCapitalization: TextCapitalization.words,
      ),
      _field(
        controller: _emailController,
        label: 'Email address',
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          final email = value?.trim() ?? '';
          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
              ? null
              : 'Enter a valid email address.';
        },
      ),
      _field(
        controller: _passwordController,
        label: 'Password',
        obscureText: _obscurePassword,
        suffix: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        validator: (value) =>
            (value?.length ?? 0) >= 6 ? null : 'Use at least 6 characters.',
      ),
      CheckboxListTile(
        value: _acceptedTerms,
        onChanged: _isLoading
            ? null
            : (value) => setState(() => _acceptedTerms = value ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I agree to the Terms of Service and identity verification.',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _isLoading ? null : _continueToApplication,
        style: _buttonStyle(),
        child: const Text('Register Trade Profile'),
      ),
    ];
  }

  List<Widget> _buildApplicationDetails() {
    return [
      _sectionCard(
        title: 'Contact and location',
        children: [
          _field(
            controller: _phoneController,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
            validator: _requiredValidator,
          ),
          _field(
            controller: _locationController,
            label: 'City / work location',
            validator: _requiredValidator,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(title: 'Professional details', children: _roleFields()),
      const SizedBox(height: 12),
      _sectionCard(
        title: 'CV or supporting document',
        children: [
          const Text(
            'Upload a CV, work history or company profile (PDF, DOC, DOCX; up to 10 MB).',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickCv,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _cvFile == null ? 'Choose document' : 'Change document',
            ),
          ),
          if (_cvFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Color(0xFF009B9D),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _cvFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _cvFile = null),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove document',
                ),
              ],
            ),
          ],
          if (_cvFile == null && widget.draft?.cvFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Attached: ${widget.draft!.cvFileName}',
              style: const TextStyle(
                color: Color(0xFF008C96),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F7F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFF008C96)),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Your account stays inactive until an administrator reviews and approves this application. You will see any interview invitation here after signing in.',
                style: TextStyle(
                  color: Color(0xFF31515C),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: _isLoading ? null : _submitApplication,
          style: _buttonStyle(),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit application for review'),
        ),
      ),
    ];
  }

  List<Widget> _roleFields() {
    switch (_role) {
      case 'Tradesperson':
        return [
          _field(
            controller: _tradeController,
            label: 'Trade / occupation',
            validator: _requiredValidator,
          ),
          _field(
            controller: _experienceController,
            label: 'Years of experience',
            keyboardType: TextInputType.number,
            validator: _requiredValidator,
          ),
          _field(
            controller: _qualificationController,
            label: 'Licenses and qualifications',
            validator: _requiredValidator,
          ),
          _field(
            controller: _historyController,
            label: 'Relevant work experience',
            minLines: 3,
            validator: _requiredValidator,
          ),
        ];
      case 'Employer / Contractor':
        return [
          _field(
            controller: _companyController,
            label: 'Company / contractor name',
            validator: _requiredValidator,
          ),
          _field(
            controller: _industryController,
            label: 'Business sector',
            validator: _requiredValidator,
          ),
          _field(
            controller: _registrationController,
            label: 'Company registration (optional)',
          ),
          _field(
            controller: _hiringNeedsController,
            label: 'Hiring and project needs',
            minLines: 3,
            validator: _requiredValidator,
          ),
          _field(
            controller: _historyController,
            label: 'Relevant industry experience',
            minLines: 2,
            validator: _requiredValidator,
          ),
        ];
      case 'Trainer / Assessor':
        return [
          _field(
            controller: _specialtyController,
            label: 'Training specialty',
            validator: _requiredValidator,
          ),
          _field(
            controller: _experienceController,
            label: 'Years of training / trade experience',
            keyboardType: TextInputType.number,
            validator: _requiredValidator,
          ),
          _field(
            controller: _certificationsController,
            label: 'Certifications and accreditations',
            validator: _requiredValidator,
          ),
          _field(
            controller: _historyController,
            label: 'Training and assessment experience',
            minLines: 3,
            validator: _requiredValidator,
          ),
        ];
    }
    return const <Widget>[];
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    bool obscureText = false,
    Widget? suffix,
    int minLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        minLines: minLines,
        maxLines: obscureText ? 1 : (minLines > 1 ? 5 : 1),
        style: const TextStyle(color: Color(0xFF10243B), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFFBFCFE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF009B9D), width: 1.4),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
    backgroundColor: const Color(0xFF009B9D),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
  );
}

class _AccountRole {
  const _AccountRole(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}
