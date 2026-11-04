import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _registering = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    if (_loading) return;

    _formKey.currentState?.reset();
    _passwordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _registering = !_registering;
      _errorMessage = null;
    });
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password that meets the account requirements.';
      case 'email-already-in-use':
        return 'Unable to create this account. Try signing in instead.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
      case 'user-disabled':
        return 'Unable to sign in. Check your email and password.';
      case 'network-request-failed':
        return 'Unable to connect. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment before trying again.';
      case 'operation-not-allowed':
        return 'Email and password authentication is currently unavailable.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_registering) {
        await widget.authService.register(email, password);
      } else {
        await widget.authService.signIn(email, password);
      }

      // AuthGate will choose the signed-in screen from auth state.
      // Do not push a competing route after authentication.
      if (!mounted) return;

      _passwordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to complete the request. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_registering ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Autumn Product Manager',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registering
                          ? 'Create an account to continue.'
                          : 'Sign in to access your profile.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Enter your email address.';
                        }

                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(email)) {
                          return 'Enter a valid email address.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: _registering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password.';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_registering) _submit();
                      },
                    ),
                    if (_registering) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_loading,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password.';
                          }

                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: 'Authenticating',
                              ),
                            )
                          : Text(_registering ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _switchMode,
                      child: Text(
                        _registering
                            ? 'Already have an account? Sign in'
                            : 'Need an account? Register',
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
