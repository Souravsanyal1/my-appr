import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthService extends GetxService {
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('FirebaseAuth instance notice: $e');
    }
    return null;
  }

  final Rx<User?> currentUser = Rx<User?>(null);

  bool get isLoggedIn => currentUser.value != null;
  bool get isAnonymous => currentUser.value?.isAnonymous ?? false;
  String get uid => currentUser.value?.uid ?? '';
  String? get email => currentUser.value?.email;

  @override
  void onInit() {
    super.onInit();
    try {
      final auth = _auth;
      if (auth != null) {
        currentUser.value = auth.currentUser;
        auth.authStateChanges().listen((user) {
          currentUser.value = user;
        });
      }
    } catch (e) {
      debugPrint('FirebaseAuth onInit notice: $e');
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth?.signInAnonymously();
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
      return await _auth?.signInWithEmailAndPassword(
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
      return await _auth?.createUserWithEmailAndPassword(
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
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Error signOut: $e');
    }
  }
}
