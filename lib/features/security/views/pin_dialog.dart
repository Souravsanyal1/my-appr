import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/features/security/controllers/pin_controller.dart';

class PinDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSetupMode;
  final Function(bool success)? onResult;

  const PinDialog({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle = 'Strict Mode is active',
    this.isSetupMode = false,
    this.onResult,
  });

  static Future<bool> show({
    String title = 'Enter PIN',
    String subtitle = 'Strict Mode is active',
    bool isSetupMode = false,
  }) async {
    final result = await Get.dialog<bool>(
      PinDialog(
        title: title,
        subtitle: subtitle,
        isSetupMode: isSetupMode,
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PinController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(result: false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              String currentSubtitle = subtitle;
              if (isSetupMode) {
                currentSubtitle = controller.isConfirming.value
                    ? 'Confirm your 4-digit PIN'
                    : 'Choose a 4-digit security PIN';
              }
              return Text(
                currentSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }),
            const SizedBox(height: 24),
            // PIN Dots Indicator
            Obx(() {
              final len = controller.enteredPin.value.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < len;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.primaryGold
                          : (isDark ? Colors.white24 : Colors.black12),
                      border: isFilled
                          ? Border.all(color: AppColors.primaryGold, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 12),
            // Error Message
            Obx(() {
              if (controller.errorMessage.value.isEmpty) {
                return const SizedBox(height: 20);
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  controller.errorMessage.value,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Keypad
            _buildKeypad(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, PinController controller) {
    return Column(
      children: [
        _buildRow(['1', '2', '3'], controller),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6'], controller),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9'], controller),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.refresh,
              onTap: controller.clear,
            ),
            _buildDigitButton('0', controller),
            _buildActionButton(
              icon: Icons.backspace_outlined,
              onTap: controller.backspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits, PinController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d, controller)).toList(),
    );
  }

  Widget _buildDigitButton(String digit, PinController controller) {
    return InkWell(
      onTap: () {
        controller.appendDigit(digit);
        if (controller.enteredPin.value.length == 4) {
          if (isSetupMode) {
            final complete = controller.setupNewPin();
            if (complete) {
              Get.back(result: true);
            }
          } else {
            final valid = controller.verify();
            if (valid) {
              Get.back(result: true);
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: Icon(icon, size: 24),
      ),
    );
  }
}
