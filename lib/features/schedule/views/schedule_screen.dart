import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../controllers/schedule_controller.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Block Schedules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Schedule',
            onPressed: () => _showEditScheduleDialog(context, null),
          ),
        ],
      ),
      body: Obx(() {
        final list = controller.schedules;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.alarm_off_outlined,
                  size: 56,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No schedules configured',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showEditScheduleDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Schedule'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final schedule = list[index];
            final isCurrentlyActive = schedule.isTimeActive(DateTime.now());

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isCurrentlyActive
                      ? AppColors.primaryEmerald
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: isCurrentlyActive ? 1.5 : 1.0,
                ),
              ),
              color: isDark ? const Color(0xFF14201C) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      schedule.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCurrentlyActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryEmerald,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'ACTIVE NOW',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schedule.timeRangeString,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: schedule.isEnabled,
                          activeThumbColor: AppColors.primaryEmerald,
                          onChanged: (_) =>
                              controller.toggleSchedule(schedule.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            schedule.repeatType.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (schedule.blockedPackages.isNotEmpty) ...[
                                ...schedule.blockedPackages.take(3).map(
                                      (pkg) => Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: AppIconWidget(
                                          packageName: pkg,
                                          size: 16,
                                          borderRadius: 4,
                                        ),
                                      ),
                                    ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                '${schedule.blockedPackages.length} Apps Blocked',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showEditScheduleDialog(context, schedule),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          tooltip: 'Delete',
                          onPressed: () =>
                              controller.deleteSchedule(schedule.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditScheduleDialog(context, null),
        backgroundColor: AppColors.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, ScheduleModel? existing) {
    final controller = Get.find<ScheduleController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(
      text: existing?.name ?? 'Study Time',
    );

    TimeOfDay startTime = TimeOfDay(
      hour: existing?.startHour ?? 14,
      minute: existing?.startMinute ?? 0,
    );
    TimeOfDay endTime = TimeOfDay(
      hour: existing?.endHour ?? 17,
      minute: existing?.endMinute ?? 0,
    );
    ScheduleRepeatType repeatType =
        existing?.repeatType ?? ScheduleRepeatType.daily;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14201C) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'New Schedule' : 'Edit Schedule',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setState(() => startTime = picked);
                            }
                          },
                          child: Text('Start: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setState(() => endTime = picked);
                            }
                          },
                          child: Text('End: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ScheduleRepeatType>(
                    initialValue: repeatType,
                    decoration: const InputDecoration(
                      labelText: 'Repeat Schedule',
                      border: OutlineInputBorder(),
                    ),
                    items: ScheduleRepeatType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => repeatType = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim().isEmpty
                            ? 'Block Schedule'
                            : nameCtrl.text.trim();
                        final id =
                            existing?.id ??
                            'schedule_${DateTime.now().millisecondsSinceEpoch}';
                        final updated = ScheduleModel(
                          id: id,
                          name: name,
                          startHour: startTime.hour,
                          startMinute: startTime.minute,
                          endHour: endTime.hour,
                          endMinute: endTime.minute,
                          repeatType: repeatType,
                          blockedPackages:
                              existing?.blockedPackages ??
                              [
                                'com.zhiliaoapp.musically',
                                'com.instagram.android',
                                'com.facebook.katana',
                              ],
                          isEnabled: existing?.isEnabled ?? true,
                        );
                        controller.addOrUpdateSchedule(updated);
                        Get.back();
                      },
                      child: const Text('Save Schedule'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
