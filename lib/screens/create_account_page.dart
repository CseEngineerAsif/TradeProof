import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'employer_dashboard_page.dart';
import 'private_client_dashboard_page.dart';
import 'trainer_dashboard_page.dart';
import 'tradeworker.dart';

// Collects the details needed to create a TradeProof account.
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  // These are the account roles a new user can choose from.
  static const _roles = <_AccountRole>[
    _AccountRole(
      'Tradesperson',
      'Prove competency, store licenses, share work portfolio.',
    ),
    _AccountRole(
      'Employer / Contractor',
      'Audit site compliance and instantly verify worker credentials.',
    ),
    _AccountRole(
      'Trainer / Assessor',
      'Evaluate practical competency and issue verified stamps.',
    ),
    _AccountRole(
      'General User',
      'Hire verified tradespeople, find practical courses and manage requests.',
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRole = 0;
  bool _acceptedTerms = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Removes the text controllers when this page is closed.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Checks the form, creates the account, and opens its matching dashboard.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError(
        'Please agree to the Terms of Service and identity verification.',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.createAccount(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _roles[_selectedRole].title,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) {
            final role = _roles[_selectedRole].title;
            if (role == 'Employer / Contractor') {
              return const EmployerDashboardPage();
            }
            if (role == 'Trainer / Assessor') {
              return const TrainerDashboardPage();
            }
            if (role == 'General User' ||
                role == 'User' ||
                role == 'Private Client') {
              return const PrivateClientDashboardPage();
            }
            return const AuthenticatedShell();
          },
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showError(authErrorMessage(error));
    } on FirebaseException catch (error) {
      _showError(authErrorMessage(error));
    } catch (error) {
      _showError(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Shows a form error at the bottom of the screen.
  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // This form collects personal details and the account role.
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE0E6EE)),
                            fixedSize: const Size(32, 32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Color(0xFF10243B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Step 1 of 2: Select your portal role',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_roles.length, (index) {
                      final role = _roles[index];
                      final selected = index == _selectedRole;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: InkWell(
                          onTap: _isLoading
                              ? null
                              : () => setState(() => _selectedRole = index),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 47),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
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
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: 17,
                                  color: selected
                                      ? const Color(0xFF009E9A)
                                      : const Color(0xFF94A7C1),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.title,
                                        style: const TextStyle(
                                          color: Color(0xFF10243B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        role.description,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 8,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    const _FieldLabel('FULL NAME'),
                    const SizedBox(height: 5),
                    _RegisterTextField(
                      controller: _nameController,
                      hint: 'e.g. Jack Carter',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const _FieldLabel('EMAIL ADDRESS'),
                    const SizedBox(height: 5),
                    _RegisterTextField(
                      controller: _emailController,
                      hint: 'e.g. jack@carter-electrical.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const _FieldLabel('PASSWORD'),
                    const SizedBox(height: 5),
                    _RegisterTextField(
                      controller: _passwordController,
                      hint: 'Enter secure password',
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 17,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: _isLoading
                                ? null
                                : (value) => setState(
                                    () => _acceptedTerms = value ?? false,
                                  ),
                            visualDensity: VisualDensity.compact,
                            activeColor: const Color(0xFF009E9A),
                            side: const BorderSide(color: Color(0xFF009E9A)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 9,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: Color(0xFF008C96),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Consent to Identity Verification.',
                                    style: TextStyle(
                                      color: Color(0xFF008C96),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _register,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF009B9D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Register Trade Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Stores the title and help text for one account role.
class _AccountRole {
  const _AccountRole(this.title, this.description);

  final String title;
  final String description;
}

// Displays a short label above an input field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF10243B),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    ),
  );
}

// Reusable input field for the registration form.
class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    style: const TextStyle(fontSize: 11, color: Color(0xFF10243B)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AAAC0), fontSize: 11),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFF008C96)),
      ),
      errorStyle: const TextStyle(fontSize: 9),
    ),
  );
}
