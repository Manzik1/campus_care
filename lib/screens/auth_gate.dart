import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          return const _AuthErrorScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return _AccountAccessGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _AccountAccessGate extends StatefulWidget {
  final User user;

  const _AccountAccessGate({super.key, required this.user});

  @override
  State<_AccountAccessGate> createState() => _AccountAccessGateState();
}

class _AccountAccessGateState extends State<_AccountAccessGate> {
  late Future<bool> _accessFuture;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    _accessFuture = AuthService().canAccessApp(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          return const _AuthErrorScreen();
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const VerifyEmailScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Unable to check your account. Please try again later.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
