import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String studentDomain = 'alustudent.com';

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();

    if (!normalizedEmail.endsWith('@$studentDomain')) {
      throw Exception(
        'Please use your official ALU student email '
        '(@$studentDomain).',
      );
    }

    if (normalizedName.isEmpty) {
      throw Exception('Please enter your name.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user!;

    final userDocument = _firestore.collection('users').doc(user.uid);

    try {
      await user.updateDisplayName(normalizedName);

      await userDocument.set({
        'name': normalizedName,
        'email': normalizedEmail,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      try {
        await userDocument.delete();
      } catch (_) {
        // Continue cleanup even if the profile does not exist.
      }

      try {
        await user.delete();
      } catch (_) {
        // Preserve the original error.
      }

      rethrow;
    }

    // Keep the account and profile if email delivery fails.
    // The student can request another verification email.
    await user.sendEmailVerification();

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    return _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in again to resend the verification email.');
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw Exception('Your session has expired. Please log in again.');
    }

    if (refreshedUser.emailVerified) {
      throw Exception('Your email is already verified.');
    }

    await refreshedUser.sendEmailVerification();
  }

  Future<bool> checkEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<String> getUserRole(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    final role = document.data()?['role'];

    if (role != 'student' && role != 'staff') {
      throw StateError(
        'Your account does not have a valid user role. '
        'Please contact the administrator.',
      );
    }

    return role as String;
  }

  Future<bool> canAccessApp(User user) async {
    final role = await getUserRole(user.uid);

    // Staff accounts do not require student email verification.
    if (role == 'staff') {
      return true;
    }

    return user.emailVerified;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
