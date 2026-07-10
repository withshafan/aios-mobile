import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  User? get user => _user;
  GoogleSignInAccount? _googleUser;
  GoogleSignInAccount? get googleUser => _googleUser;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/calendar.events', // allow create/delete events
        ],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      _googleUser = googleUser;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      notifyListeners();
    } catch (e) {
      debugPrint('Google sign in error: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _googleUser = null;
    notifyListeners();
  }
}
