import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:focus_deen/features/dhikr/models/dhikr_model.dart';

class DhikrController extends GetxController {
  final _box = GetStorage();

  static const String _keyTotalCount = 'total_dhikr_count';

  final List<DhikrModel> dhikrList = const [
    DhikrModel(
      id: 'subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'SubhanAllah',
      translation: 'Glory be to Allah',
      targetCount: 33,
      virtue: 'Plants a palm tree in Paradise for the believer.',
    ),
    DhikrModel(
      id: 'alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translation: 'All praise is due to Allah',
      targetCount: 33,
      virtue: 'Fills the Scale (Mizan) with good deeds.',
    ),
    DhikrModel(
      id: 'allahuakbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      targetCount: 34,
      virtue: 'Better than a servant for the home, taught by Prophet ﷺ to Fatimah (RA).',
    ),
    DhikrModel(
      id: 'astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      targetCount: 100,
      virtue: 'Removes distress, opens doors of sustenance and relief.',
    ),
    DhikrModel(
      id: 'lailahaillallah',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      transliteration: 'La ilaha illallah',
      translation: 'None has the right to be worshipped but Allah',
      targetCount: 100,
      virtue: 'The best dhikr and key to Jannah.',
    ),
    DhikrModel(
      id: 'subhanallahi_wabihamdihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      translation: 'Glory be to Allah and His is the praise',
      targetCount: 100,
      virtue: 'Sins are forgiven even if they were like the foam of the sea.',
    ),
  ];

  final RxInt selectedDhikrIndex = 0.obs;
  final RxInt currentCount = 0.obs;
  final RxInt totalLifetimeCount = 0.obs;

  DhikrModel get currentDhikr => dhikrList[selectedDhikrIndex.value];

  @override
  void onInit() {
    super.onInit();
    totalLifetimeCount.value = _box.read<int>(_keyTotalCount) ?? 0;
  }

  void selectDhikr(int index) {
    if (index >= 0 && index < dhikrList.length) {
      selectedDhikrIndex.value = index;
      currentCount.value = 0;
    }
  }

  void increment() {
    HapticFeedback.lightImpact();
    currentCount.value++;
    totalLifetimeCount.value++;
    _box.write(_keyTotalCount, totalLifetimeCount.value);

    // If target reached
    if (currentCount.value == currentDhikr.targetCount) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
        'Target Reached! 🌟',
        'You completed ${currentDhikr.targetCount}x of ${currentDhikr.transliteration}. May Allah accept your dhikr.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void resetCurrent() {
    currentCount.value = 0;
    HapticFeedback.mediumImpact();
  }

  double get progress {
    if (currentDhikr.targetCount == 0) return 0.0;
    return (currentCount.value / currentDhikr.targetCount).clamp(0.0, 1.0);
  }
}
