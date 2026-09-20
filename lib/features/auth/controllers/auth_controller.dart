import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/firebase_auth_service.dart';
import 'package:focus_deen/core/services/firestore_sync_service.dart';

class AuthController extends GetxController {
  final FirebaseAuthService authService = Get.find<FirebaseAuthService>();
  final FirestoreSyncService syncService = Get.find<FirestoreSyncService>();

  final RxBool isSignUpMode = false.obs;
  final RxBool isLoading = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleMode() {
    isSignUpMode.value = !isSignUpMode.value;
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password.');
      return;
    }

    isLoading.value = true;
    try {
      if (isSignUpMode.value) {
        await authService.signUpWithEmail(email: email, password: password);
        await syncService.backupToCloud();
        Get.snackbar('Account Created', 'Welcome to FocusDeen!');
      } else {
        await authService.signInWithEmail(email: email, password: password);
        await syncService.restoreFromCloud();
        Get.snackbar('Signed In', 'Welcome back to FocusDeen!');
      }
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar('Authentication Failed', e.toString().split(']').last.trim());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueAsGuest() async {
    isLoading.value = true;
    try {
      await authService.signInAnonymously();
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.offAllNamed('/dashboard'); // Allow offline guest even if network fails
    } finally {
      isLoading.value = false;
    }
  }
}
