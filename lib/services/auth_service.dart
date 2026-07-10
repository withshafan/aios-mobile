import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/connected_services_service.dart';
import '../services/multi_llm_service.dart';
import '../services/agent_team_service.dart';

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
      if (_auth.currentUser != null) {
        await ConnectedServicesService.seedAvailableServices(FirebaseFirestore.instance, _auth.currentUser!.uid);
        await MultiLLMService.seedDefaults(FirebaseFirestore.instance, _auth.currentUser!.uid);
        final teamService = AgentTeamService();
        await teamService.seedTeam();
      }
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
