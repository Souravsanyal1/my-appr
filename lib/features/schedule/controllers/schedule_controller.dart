import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/schedule_model.dart';

class ScheduleController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<ScheduleModel> schedules = <ScheduleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSchedules();
    });
  }

  void loadSchedules() {
    final rawList = _storageService.read<List<dynamic>>('user_schedules');
    if (rawList != null && rawList.isNotEmpty) {
      schedules.assignAll(
        rawList
            .map(
              (m) => ScheduleModel.fromMap(Map<String, dynamic>.from(m as Map)),
            )
            .toList(),
      );
    } else {
      // Default presets as requested in prompt Section 18
      final defaultSchedules = [
        const ScheduleModel(
          id: 'preset_study_time',
          name: 'Study Time',
          startHour: 14,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
          repeatType: ScheduleRepeatType.daily,
          blockedPackages: [
            'com.zhiliaoapp.musically',
            'com.instagram.android',
            'com.facebook.katana',
            'com.google.android.youtube',
          ],
          isEnabled: true,
        ),
        const ScheduleModel(
          id: 'preset_night_mode',
          name: 'Night Mode',
          startHour: 23,
          startMinute: 0,
          endHour: 7,
          endMinute: 0,
          repeatType: ScheduleRepeatType.daily,
          blockedPackages: [
            'com.zhiliaoapp.musically',
            'com.instagram.android',
            'com.facebook.katana',
            'com.reddit.frontpage',
          ],
          isEnabled: true,
        ),
      ];
      schedules.assignAll(defaultSchedules);
      _persist();
    }
  }

  void _persist() {
    _storageService.write(
      'user_schedules',
      schedules.map((s) => s.toMap()).toList(),
    );
  }

  void toggleSchedule(String id) {
    final index = schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = schedules[index];
      schedules[index] = current.copyWith(isEnabled: !current.isEnabled);
      _persist();
    }
  }

  void addOrUpdateSchedule(ScheduleModel schedule) {
    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }
    _persist();
  }

  void deleteSchedule(String id) {
    schedules.removeWhere((s) => s.id == id);
    _persist();
  }

  bool isPackageBlockedBySchedule(String packageName, [DateTime? time]) {
    final checkTime = time ?? DateTime.now();
    for (final schedule in schedules) {
      if (schedule.isTimeActive(checkTime)) {
        if (schedule.blockedPackages.contains(packageName)) {
          return true;
        }
      }
    }
    return false;
  }
}
