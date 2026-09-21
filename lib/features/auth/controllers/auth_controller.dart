import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/firebase_auth_service.dart';
import 'package:focus_deen/core/services/firebase_realtime_service.dart';
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
      Get.snackbar(
        'Authentication Failed',
        e.toString().split(']').last.trim(),
      );
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
      Get.offAllNamed(
        '/dashboard',
      ); // Allow offline guest even if network fails
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> backupNow() async {
    isLoading.value = true;
    try {
      final success = await syncService.backupToCloud();
      if (success) {
        Get.snackbar(
          'Backup Complete',
          'Your limits and rules are saved in Cloud Firestore.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Backup Failed',
          'Could not sync to cloud.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreNow() async {
    isLoading.value = true;
    try {
      final success = await syncService.restoreFromCloud();
      if (success) {
        Get.snackbar(
          'Restored',
          'Your limits were restored from Cloud Firestore.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Restore Failed',
          'No backup found or sync error.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> testRealtimeSync() async {
    try {
      if (Get.isRegistered<FirebaseRealtimeService>()) {
        await Get.find<FirebaseRealtimeService>().updateUserPresence(
          isOnline: true,
        );
        Get.snackbar(
          'Realtime DB Connected',
          'Live presence and sync confirmed.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Realtime DB Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> signOut() async {
    await authService.signOut();
    Get.snackbar('Signed Out', 'You have been signed out.');
  }
}
