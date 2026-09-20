import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/features/auth/controllers/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.emeraldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.cloud_sync_outlined, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              Obx(() => Text(
                    controller.isSignUpMode.value ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 6),
              Text(
                'Sync your limits, focus stats, and passes securely across your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 28),

              // Form Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : controller.submit,
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    controller.isSignUpMode.value ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        )),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.toggleMode,
                      child: Obx(() => Text(
                            controller.isSignUpMode.value
                                ? 'Already have an account? Sign In'
                                : "Don't have an account? Sign Up",
                            style: const TextStyle(color: AppColors.primaryGold),
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue as Guest Option
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue Offline / As Guest'),
                onPressed: controller.continueAsGuest,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
