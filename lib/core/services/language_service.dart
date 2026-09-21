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
      // ScrollDeeds reference flow & dashboard keys
      'time_remaining': {'en': 'Time Remaining', 'bn': 'অবশিষ্ট সময়'},
      'apps_currently_unlocked': {
        'en': 'APPS CURRENTLY UNLOCKED',
        'bn': 'অ্যাপসমূহ বর্তমানে আনলকড',
      },
      'apps_currently_locked': {
        'en': 'APPS CURRENTLY LOCKED',
        'bn': 'অ্যাপসমূহ বর্তমানে লকড',
      },
      'add_more_time': {'en': 'Add more time', 'bn': 'আরও সময় যোগ করুন'},
      'add_time_description': {
        'en': 'Do another good deed to add time to your unlock. Your remaining time will stack.',
        'bn': 'আপনার আনলক সময়ে আরও সময় যোগ করতে আরেকটি নেক আমল করুন। আপনার অবশিষ্ট সময় যুক্ত হবে।',
      },
      'do_another_deed': {
        'en': 'Do another good deed →',
        'bn': 'আরেকটি আমল করুন →',
      },
      'locked_apps': {'en': 'Locked Apps', 'bn': 'লক করা অ্যাপসমূহ'},
      'choose_apps_to_lock': {
        'en': 'Choose Apps to Lock',
        'bn': 'লক করার অ্যাপ নির্বাচন করুন',
      },
      'app_icons_privacy_note': {
        'en': 'App icons hidden for privacy',
        'bn': 'গোপনীয়তার সুরক্ষায় অ্যাপ আইকন লুকানো রয়েছে',
      },
      'nav_stats': {'en': 'Stats', 'bn': 'পরিসংখ্যান'},
      'nav_unlock': {'en': 'Unlock', 'bn': 'আনলক'},
      'nav_settings': {'en': 'Settings', 'bn': 'সেটিংস'},
      'streak_label': {'en': 'Streak', 'bn': 'ধারাবাহিকতা'},
      'streak_days': {'en': '%s days', 'bn': '%s দিন'},
      'all_apps_locked': {
        'en': 'All protected apps are locked',
        'bn': 'সুরক্ষিত সকল অ্যাপ লক করা আছে',
      },
      'apps_unlocked_desc': {
        'en': 'Protected apps are accessible until the timer expires',
        'bn': 'টাইমার শেষ না হওয়া পর্যন্ত সুরক্ষিত অ্যাপসমূহ ব্যবহারযোগ্য',
      },
      'finding_deed': {
        'en': 'Finding your good deed...',
        'bn': 'আপনার জন্য নেক আমল খোঁজা হচ্ছে...',
      },
      'translate': {'en': 'Translate', 'bn': 'অনুবাদ'},
      'tap_to_count': {'en': 'Tap to count', 'bn': 'গণনা করতে ট্যাপ করুন'},
      'mashaallah': {'en': 'MashaAllah!', 'bn': 'মাশাআল্লাহ!'},
      'access_granted': {
        'en': '+%s minutes of access',
        'bn': '+%s মিনিট ব্যবহারের সুযোগ',
      },
      'continue_btn': {'en': 'Continue', 'bn': 'চালিয়ে যান'},
      'your_apps_locked': {
        'en': 'Your apps are locked',
        'bn': 'আপনার অ্যাপসমূহ লক করা আছে',
      },
      'complete_deed_to_unlock': {
        'en': 'Complete a good deed to unlock your apps',
        'bn': 'অ্যাপসমূহ আনলক করতে একটি নেক আমল সম্পন্ন করুন',
      },
      'complete_a_good_deed': {
        'en': 'Complete a Good Deed',
        'bn': 'একটি নেক আমল সম্পন্ন করুন',
      },
      'xp_to_next': {'en': '%s XP to %s', 'bn': '%s-এ পৌঁছাতে %s XP বাকি'},
      'easy': {'en': 'Easy', 'bn': 'সহজ'},
      'medium': {'en': 'Medium', 'bn': 'মাঝারি'},
      'hard': {'en': 'Hard', 'bn': 'কঠিন'},
      'minutes_badge': {'en': '%s minutes', 'bn': '%s মিনিট'},
      'xp_badge': {'en': '+%s XP', 'bn': '+%s এক্সপি'},
      'tap_to_count_instruction': {
        'en': 'Tap the counter or use the microphone to complete',
        'bn': 'সম্পন্ন করতে কাউন্টারে ট্যাপ করুন বা মাইক্রোফোন ব্যবহার করুন',
      },
      'rank_shield_title': {'en': 'Current Rank', 'bn': 'বর্তমান পদমর্যাদা'},
      'summary': {'en': 'Summary', 'bn': 'সারসংক্ষেপ'},
      'current_streak': {'en': 'Current Streak', 'bn': 'বর্তমান ধারাবাহিকতা'},
      'longest_streak': {'en': 'Longest Streak', 'bn': 'সর্বোচ্চ ধারাবাহিকতা'},
      'total_deeds': {'en': 'Total Deeds', 'bn': 'মোট আমল'},
      'total_xp': {'en': 'Total XP', 'bn': 'মোট এক্সপি'},
      'total_time_earned': {'en': 'Total Time Earned', 'bn': 'মোট অর্জিত সময়'},
      'weekly_activity': {'en': 'Weekly Activity', 'bn': 'সাপ্তাহিক আমল'},
      'deed_history': {'en': 'Deed History', 'bn': 'আমলের ইতিহাস'},
      'no_deeds_yet': {
        'en': 'No deeds completed yet',
        'bn': 'এখনও কোনো আমল সম্পন্ন হয়নি',
      },
      'completed_at': {'en': 'Completed at', 'bn': 'সম্পন্ন হয়েছে'},
      'rank_overview': {'en': 'Rank Overview', 'bn': 'র‍্যাংক বিবরণ'},
      'recitation_optional': {
        'en': 'Mic recitation optional (tap works too)',
        'bn': 'তেলাওয়াত ঐচ্ছিক (ট্যাপ করেও গণনা সম্ভব)',
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
