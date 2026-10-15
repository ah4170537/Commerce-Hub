import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'dashboard_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AuthMessage(
            message: 'Could not verify your sign-in.\n${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }
        final user = snapshot.data;
        if (user == null) return const _AdminLoginScreen();
        return _AdminClaimGate(user: user);
      },
    );
  }
}

class _AdminClaimGate extends StatefulWidget {
  final User user;

  const _AdminClaimGate({required this.user});

  @override
  State<_AdminClaimGate> createState() => _AdminClaimGateState();
}

class _AdminClaimGateState extends State<_AdminClaimGate> {
  late Future<bool> _adminCheck;

  @override
  void initState() {
    super.initState();
    _adminCheck = _checkAdminClaim();
  }

  @override
  void didUpdateWidget(covariant _AdminClaimGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _adminCheck = _checkAdminClaim();
    }
  }

  Future<bool> _checkAdminClaim() async {
    final token = await widget.user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AuthMessage(
            message:
                'Could not verify administrator access.\n${snapshot.error}',
            onSignOut: _signOut,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoading();
        }
        if (snapshot.data != true) {
          return _AuthMessage(
            message:
                'This account is not authorized to access the admin dashboard.',
            onSignOut: _signOut,
          );
        }
        return const DashboardScreen();
      },
    );
  }

  Future<void> _signOut() => FirebaseAuth.instance.signOut();
}

class _AdminLoginScreen extends StatefulWidget {
  const _AdminLoginScreen();

  @override
  State<_AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSigningIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message ?? 'Could not sign in.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = 'Could not sign in: $error');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppColors.cardSurface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.primaryAccentLight,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin sign in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Password'),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSigningIn ? null : _signIn,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSigningIn
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
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

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryAccent),
    ),
  );
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onSignOut;

  const _AuthMessage({required this.message, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              if (onSignOut != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onSignOut,
                  child: const Text('Sign out'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
