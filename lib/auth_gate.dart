import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'authentication_screen.dart';
import 'profile_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Keep the service and its auth-state stream stable across rebuilds.
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to check sign-in status. '
                    'Close and reopen the app to try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Checking sign-in status',
              ),
            ),
          );
        }

        final user = snapshot.data;

        // A separate navigator keeps signed-in dialogs and routes inside
        // this session. Signing out removes that entire navigator.
        return Navigator(
          key: ValueKey<String>(user?.uid ?? 'signed-out'),
          onGenerateRoute: (_) {
            return MaterialPageRoute<void>(
              builder: (_) {
                if (user == null) {
                  return AuthenticationScreen(authService: _authService);
                }

                return ProfileScreen(authService: _authService);
              },
            );
          },
        );
      },
    );
  }
}
