import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Keep one stable stream for auth-state routing.
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    final user = _requireUser();
    await user.updatePassword(newPassword);
  }

  // Called when a password update requires a recent sign-in.
  // Neither password is logged or saved by this service.
  Future<void> reauthenticateAndChangePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser();
    final email = user.email;

    if (email == null || email.isEmpty) {
      throw StateError('The signed-in account has no email address.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Avoid updating a different account if auth state changed.
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('The signed-in account changed. Please try again.');
    }

    await user.updatePassword(newPassword);
  }

  User _requireUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before changing your password.');
    }

    return user;
  }
}
