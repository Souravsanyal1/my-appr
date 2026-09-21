import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/inbox_notification_model.dart';

class NotificationsInboxView extends StatelessWidget {
  const NotificationsInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = NotificationService.to;
    final lang = LanguageService.to;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Obx(() {
          final isBn = lang.isBangla;
          final unread = notifService.unreadCount.value;
          return Row(
            children: [
              const Icon(Iconsax.notification, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                isBn ? 'বিজ্ঞপ্তিসমূহ' : 'Notifications',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        actions: [
          Obx(() {
            if (notifService.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: notifService.markAllRead,
              child: Text(
                lang.isBangla ? 'সব পড়া হয়েছে' : 'Mark all read',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brightGreen,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final items = notifService.inbox;
        if (items.isEmpty) {
          return _buildEmptyState(lang.isBangla);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildInboxTile(
              item: item,
              onTap: () {
                notifService.markRead(item.id);
                if (item.route != null && item.route!.isNotEmpty) {
                  Get.toNamed(item.route!);
                }
              },
              onDelete: () => notifService.deleteNotification(item.id),
            );
          },
        );
      }),
    );
  }

  Widget _buildInboxTile({
    required InboxNotificationModel item,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final timeStr = _formatTime(item.receivedAt);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Iconsax.trash, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? AppColors.cardBackground
                : AppColors.brightGreen.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppColors.border
                  : AppColors.brightGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isRead
                      ? AppColors.surface
                      : AppColors.brightGreen.withValues(alpha: 0.15),
                  border: Border.all(
                    color: item.isRead
                        ? AppColors.border
                        : AppColors.brightGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.isRead ? Iconsax.notification : Iconsax.notification_1,
                    size: 20,
                    color: item.isRead
                        ? AppColors.textSecondary
                        : AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brightGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.clock,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (item.route != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Iconsax.arrow_right_3,
                            size: 12,
                            color: AppColors.brightGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.route!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isBn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Icon(
                  Iconsax.notification_bing,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isBn ? 'কোনো বিজ্ঞপ্তি নেই' : 'No notifications yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'আপনার প্রাপ্ত বিজ্ঞপ্তিগুলো এখানে দেখাবে'
                  : 'Your notifications will appear here when received',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
