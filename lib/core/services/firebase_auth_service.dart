import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FirebaseAuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<User?> currentUser = Rx<User?>(null);

  bool get isLoggedIn => currentUser.value != null;
  bool get isAnonymous => currentUser.value?.isAnonymous ?? false;
  String get uid => currentUser.value?.uid ?? '';
  String? get email => currentUser.value?.email;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
    });
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Error signInAnonymously: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error signInWithEmail: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error signUpWithEmail: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signOut: $e');
    }
  }
}
