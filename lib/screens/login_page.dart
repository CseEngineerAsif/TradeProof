import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'employer_dashboard_page.dart';
import 'private_client_dashboard_page.dart';
import 'trainer_dashboard_page.dart';
import 'tradeworker.dart';

// Collects login details and opens the correct page for the account role.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Removes the text controllers when this page is closed.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Checks the form, signs in, and opens the page for the user's role.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final role = await AuthService.currentUserRole();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) {
            if (role == 'Employer / Contractor' || role == 'Employer') {
              return const EmployerDashboardPage();
            }
            if (role == 'Trainer / Assessor' || role == 'Trainer') {
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

  // Opens a sample account without creating or signing into a real account.
  void _continueAsDemo(String role) {
    ConnectionService.beginDemoSession(role);
    final Widget page;
    switch (role) {
      case 'Employer':
        page = const EmployerDashboardPage(isDemo: true);
      case 'Trainer':
        page = const TrainerDashboardPage(isDemo: true);
      case 'User':
      case 'Private Client':
        page = const PrivateClientDashboardPage(isDemo: true);
      default:
        page = AuthenticatedShell(isDemo: true, demoRole: role);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (_) => false,
    );
  }

  // Builds one button for entering a sample role.
  Widget _demoLoginButton(String role, IconData icon) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () => _continueAsDemo(role),
        icon: Icon(icon, size: 15),
        label: Text(role, style: const TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF008C96),
          side: const BorderSide(color: Color(0xFF008C96)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }

  // Sends a password reset email to the address in the email field.
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter your email address first to reset your password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        _showMessage('Password reset email sent. Check your inbox.');
      }
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

  // Shows an error or information message at the bottom of the screen.
  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Collect the user's email and password in this form.
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Color(0xFF10243B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Verify identity to access your compliance locker.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 96),
                      _FieldLabel('EMAIL ADDRESS'),
                      const SizedBox(height: 5),
                      _AuthTextField(
                        controller: _emailController,
                        hint: 'e.g. j.carter@tradeproof.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('PASSWORD'),
                      const SizedBox(height: 5),
                      _AuthTextField(
                        controller: _passwordController,
                        hint: 'Enter secure password',
                        icon: Icons.lock_outline,
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
                            size: 18,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF008C96),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1B2E),
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
                                  'Secure Login',
                                  style: TextStyle(fontSize: 12),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'DEMO LOGIN AS',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _demoLoginButton(
                              'Tradesperson',
                              Icons.handyman_outlined,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _demoLoginButton(
                              'Employer',
                              Icons.business_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _demoLoginButton(
                              'Trainer',
                              Icons.school_outlined,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _demoLoginButton(
                              'User',
                              Icons.person_search_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Demo mode does not sign in or create an account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFE0E6EE))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'OR SECURE BIOMETRICS',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE0E6EE))),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          width: 134,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE0E6EE)),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.fingerprint,
                                color: Color(0xFF00A3A6),
                                size: 32,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Sign in with Face / Finger',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'New to TradeProof? ',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pushNamed('/register'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Color(0xFF008C96),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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
          },
        ),
      ),
    );
  }
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

// Reusable input field for the login form.
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 11, color: Color(0xFF10243B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AAAC0), fontSize: 11),
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A7C1)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 10,
        ),
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
}
