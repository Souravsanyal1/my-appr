import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../widgets/progress_ring.dart';
import 'storage_service.dart';

class LanguageService extends GetxService {
  static LanguageService get to => Get.find<LanguageService>();

  static const String keyLanguage = 'selected_language';
  final RxString currentLanguage = 'bn'.obs;

  bool get isBangla => currentLanguage.value == 'bn';

  Future<LanguageService> init() async {
    final storage = Get.find<StorageService>();
    final saved = storage.read<String>(keyLanguage);
    if (saved != null && (saved == 'bn' || saved == 'en')) {
      currentLanguage.value = saved;
    } else {
      // Default to Bengali as requested by user
      currentLanguage.value = 'bn';
      storage.write(keyLanguage, 'bn');
    }
    return this;
  }

  void changeLanguage(String code) {
    if (code != 'bn' && code != 'en') return;
    currentLanguage.value = code;
    Get.find<StorageService>().write(keyLanguage, code);
  }

  void toggleLanguage() {
    changeLanguage(isBangla ? 'en' : 'bn');
  }

  // Quick helper for UI labels
  String t(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'app_name': {'en': 'DeenFlow', 'bn': 'দ্বীনফ্লো'},
      'home': {'en': 'Home', 'bn': 'হোম'},
      'progress': {'en': 'Progress', 'bn': 'অগ্রগতি'},
      'deeds': {'en': 'Deeds', 'bn': 'আমল'},
      'profile': {'en': 'Profile', 'bn': 'প্রোফাইল'},
      'today_progress': {'en': "Today's progress", 'bn': 'আজকের অগ্রগতি'},
      'deeds_completed': {'en': 'deeds completed', 'bn': 'টি আমল সম্পন্ন'},
      'protected_apps': {'en': 'Protected Apps', 'bn': 'সুরক্ষিত অ্যাপসমূহ'},
      'next_deed': {'en': 'NEXT DEED', 'bn': 'পরবর্তী আমল'},
      'start': {'en': 'Start →', 'bn': 'শুরু করুন →'},
      'deeds_library': {'en': 'Deeds Library', 'bn': 'আমল লাইব্রেরি'},
      'deeds_subtitle': {
        'en': 'Select a mindful good deed to learn and unlock.',
        'bn': 'শিখতে ও অ্যাপ আনলক করতে একটি বরকতময় আমল নির্বাচন করুন।',
      },
      'recite_times': {'en': 'Recite %s times', 'bn': '%s বার পাঠ করুন'},
      'access_reward': {
        'en': '%s minutes access',
        'bn': '%s মিনিট ব্যবহারের সুযোগ',
      },
      'start_reciting': {'en': 'Start Reciting', 'bn': 'তেলাওয়াত শুরু করুন'},
      'learn_pronunciation': {
        'en': 'Learn Pronunciation',
        'bn': 'উচ্চারণ শিখুন',
      },
      'pronunciation_label': {'en': 'Pronunciation', 'bn': 'উচ্চারণ'},
      'meaning_label': {'en': 'Meaning', 'bn': 'অর্থ'},
      'hear_again': {'en': 'Hear Again', 'bn': 'পুনরায় শুনুন'},
      'im_ready': {'en': "I'm Ready", 'bn': 'আমি প্রস্তুত'},
      'language': {'en': 'Language', 'bn': 'ভাষা'},
      'change_language': {'en': 'Change Language', 'bn': 'ভাষা পরিবর্তন করুন'},
      'settings': {'en': 'Settings', 'bn': 'সেটিংস'},
      'set_intention': {
        'en': 'Set your intention',
        'bn': 'নিয়ত নির্ধারণ করুন',
      },
      'hold_to_set': {
        'en': 'Hold to set intention',
        'bn': 'নিয়ত করতে চেপে ধরে রাখুন',
      },
    };

    final map = localizedStrings[key];
    if (map == null) return key;
    return map[currentLanguage.value] ?? map['en'] ?? key;
  }

  void showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Obx(() {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBangla ? 'ভাষা নির্বাচন করুন' : 'Select Language',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  title: 'বাংলা (Bengali)',
                  subtitle: 'সকল আমলের বিশুদ্ধ বাংলা উচ্চারণ ও অর্থ',
                  code: 'bn',
                  flag: '🇧🇩',
                  isSelected: isBangla,
                  onTap: () {
                    changeLanguage('bn');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  title: 'English',
                  subtitle: 'Transliteration and English translation',
                  code: 'en',
                  flag: '🇬🇧',
                  isSelected: !isBangla,
                  onTap: () {
                    changeLanguage('en');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String code,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.brightGreen
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.brightGreen,
              size: 22,
            )
          else
            const Icon(
              Icons.radio_button_unchecked,
              color: AppColors.textMuted,
              size: 22,
            ),
        ],
      ),
    );
  }
}
