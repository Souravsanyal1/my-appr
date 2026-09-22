import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/notifications/models/inbox_notification_model.dart';
import 'device_identity_service.dart';
import 'language_service.dart';
import 'storage_service.dart';

const String _kInboxKey = 'local_notification_inbox';
const String _kAndroidChannelId = 'focusdeen_notifications';
const String _kAndroidChannelName = 'FocusDeen Reminders';

/// Top-level handler for background / killed-state FCM messages.
/// Must be defined at the top level and registered in main().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) return;
  debugPrint('[FCM Background] id=${message.messageId}');
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  late final StorageService _storage;

  // Reactive inbox state
  final RxList<InboxNotificationModel> inbox = <InboxNotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _loadInboxFromStorage();
  }

  Future<NotificationService> init() async {
    tz.initializeTimeZones();
    await _initLocalNotifications();
    await _initFirebaseMessaging();
    _initBroadcastSync();
    _initRtdbBroadcastSync();
    return this;
  }

  // ─── Local Notifications ──────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // v22 uses named parameter: settings:
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _kAndroidChannelId,
      _kAndroidChannelName,
      description: 'DeenFlow reminders and notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // Explicitly request POST_NOTIFICATIONS permission on Android 13+ (API 33+)
    try {
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('[Notifications] Android 13+ POST_NOTIFICATIONS granted: $granted');
    } catch (e) {
      debugPrint('[Notifications] Android permission notice: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _markReadByRoute(payload);
      Get.toNamed(payload);
    }
  }

  // ─── Firebase Messaging ───────────────────────────────────────────────────

  Future<void> _initFirebaseMessaging() async {
    if (Firebase.apps.isEmpty) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Subscribe to topics for 100% free background push via Firebase Console
    try {
      await messaging.subscribeToTopic('all_devices');
      final platformStr = defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';
      await messaging.subscribeToTopic('platform_$platformStr');
    } catch (e) {
      debugPrint('[FCM] Topic subscription error: $e');
    }

    final token = await messaging.getToken();
    if (token != null) await _onTokenReceived(token);

    messaging.onTokenRefresh.listen(_onTokenReceived);
    FirebaseMessaging.onMessage.listen(_handleIncomingMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationOpened(initialMessage);
  }

  Future<void> _onTokenReceived(String token) async {
    debugPrint('[FCM] Token: $token');
    if (Get.isRegistered<DeviceIdentityService>()) {
      await DeviceIdentityService.to.updateFcmToken(token);
    }
  }

  // ─── Message Handling ─────────────────────────────────────────────────────

  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;
    debugPrint('[FCM Foreground] type=$type id=${message.messageId}');

    final notifId = data['notificationId']?.toString() ??
        data['notifId']?.toString() ??
        message.messageId;
    if (notifId != null && notifId.isNotEmpty) {
      recordDeliveryReceipt(notifId);
    }

    if (type == 'schedule_local') {
      await _scheduleLocalFromPayload(data);
    } else if (type == 'cancel_schedule') {
      final scheduleId = int.tryParse(data['notifId'] ?? '');
      if (scheduleId != null) await _localNotifications.cancel(id: scheduleId);
    } else {
      final notification = message.notification;
      final title = notification?.title ?? data['title'] ?? '';
      final body = notification?.body ?? data['body'] ?? '';
      final route = data['route'] as String?;

      if (title.isNotEmpty) {
        final localId = notifId != null ? notifId.hashCode : message.messageId.hashCode;
        await _showLocalNow(
          id: localId,
          title: title,
          body: body,
          route: route,
        );
        _addToInbox(InboxNotificationModel(
          id: notifId ?? DateTime.now().toIso8601String(),
          title: title,
          body: body,
          imageUrl: data['imageUrl'],
          route: route,
          receivedAt: DateTime.now(),
        ));
      }
    }
  }

  void _handleNotificationOpened(RemoteMessage message) {
    final notifId = message.data['notificationId']?.toString() ??
        message.data['notifId']?.toString() ??
        message.messageId;
    if (notifId != null && notifId.isNotEmpty) {
      recordOpenedReceipt(notifId);
    }

    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      _markReadByRoute(route);
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed(route);
      });
    }
  }

  // ─── Local Notification Show Helpers ─────────────────────────────────────

  static const _androidDetails = AndroidNotificationDetails(
    _kAndroidChannelId,
    _kAndroidChannelName,
    channelDescription: 'DeenFlow reminders and notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  Future<void> _showLocalNow({
    required int id,
    required String title,
    required String body,
    String? route,
  }) async {
    // v22: show() uses named params
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: route,
    );
  }

  Future<void> _scheduleLocalFromPayload(Map<String, dynamic> data) async {
    try {
      final title = data['title'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final route = data['route'] as String?;
      final timestampMs = int.tryParse(data['scheduledTimestampMs']?.toString() ?? '') ?? 0;
      final notifId = int.tryParse(data['notifId']?.toString() ?? '0') ?? 0;

      if (title.isEmpty || timestampMs == 0) return;

      final scheduledAt = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, timestampMs);

      if (scheduledAt.isBefore(tz.TZDateTime.now(tz.local))) {
        await _showLocalNow(id: notifId, title: title, body: body, route: route);
        return;
      }

      // v22: zonedSchedule() uses named params
      await _localNotifications.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduledAt,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: route,
      );

      debugPrint('[FCM] Local alarm scheduled for $scheduledAt, id=$notifId');

      final storedId = data['notificationId']?.toString() ?? notifId.toString();
      _addToInbox(InboxNotificationModel(
        id: storedId,
        title: title,
        body: body,
        route: route,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      ));
    } catch (e) {
      debugPrint('[FCM] _scheduleLocalFromPayload error: $e');
    }
  }

  // ─── Dual-Channel Live Broadcast Sync (Firestore & Realtime Database) ─────

  void _initBroadcastSync() {
    if (Firebase.apps.isEmpty) return;

    try {
      FirebaseFirestore.instance
          .collection('notifications_broadcast')
          .snapshots()
          .listen((snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              await _processBroadcastData(change.doc.id, data);
            }
          }
        }
      }, onError: (e) {
        debugPrint('[BroadcastSync] Error listening: $e');
      });
    } catch (e) {
      debugPrint('[BroadcastSync] Init error: $e');
    }
  }

  void _initRtdbBroadcastSync() {
    if (Firebase.apps.isEmpty) return;

    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://focusdeen-f8295-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      rtdb.ref('notifications_broadcast').limitToLast(20).onChildAdded.listen(
        (event) async {
          final val = event.snapshot.value;
          if (val is Map) {
            final data = Map<String, dynamic>.from(val);
            final key = event.snapshot.key ?? '';
            await _processBroadcastData(key, data);
          }
        },
        onError: (e) {
          debugPrint('[RTDB BroadcastSync] Error: $e');
        },
      );
    } catch (e) {
      debugPrint('[RTDB BroadcastSync] Init error: $e');
    }
  }

  Future<void> _processBroadcastData(String sourceId, Map<String, dynamic> data) async {
    try {
      final notifId = data['notificationId']?.toString() ??
          data['id']?.toString() ??
          sourceId;

      final processed = List<String>.from(
        _storage.read<List<dynamic>>('processed_broadcasts') ?? <String>[],
      );
      if (processed.contains(notifId) || processed.contains(sourceId)) return;

      final targetType = data['targetType'] as String? ?? 'all';
      final currentPlatform = defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';

      if (targetType == 'platform') {
        final targetPlatform = (data['targetPlatform'] as String? ?? '').toLowerCase();
        if (targetPlatform.isNotEmpty && targetPlatform != currentPlatform) return;
      } else if (targetType == 'specific') {
        final targetDeviceId = data['targetDeviceId'] as String? ?? '';
        final myDeviceId = Get.isRegistered<DeviceIdentityService>()
            ? DeviceIdentityService.to.deviceId
            : '';
        if (targetDeviceId.isNotEmpty && targetDeviceId != myDeviceId) return;
      } else if (targetType == 'language') {
        final targetLang = (data['targetLanguage'] as String? ?? '').toLowerCase();
        final myLang = Get.isRegistered<LanguageService>()
            ? LanguageService.to.currentLanguage.value.toLowerCase()
            : 'bn';
        if (targetLang.isNotEmpty && !myLang.startsWith(targetLang)) return;
      }

      // Mark as processed so it never triggers duplicate notifications
      processed.add(sourceId);
      if (notifId != sourceId) processed.add(notifId);
      if (processed.length > 300) processed.removeRange(0, processed.length - 300);
      _storage.write('processed_broadcasts', processed);

      // Record delivery receipt to Firestore under the true notification ID
      recordDeliveryReceipt(notifId);

      final title = data['title'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final route = data['route'] as String?;
      final isScheduled = data['isScheduled'] as bool? ?? false;
      final scheduledTimestampMs = data['scheduledTimestampMs'] is int
          ? data['scheduledTimestampMs'] as int
          : int.tryParse(data['scheduledTimestampMs']?.toString() ?? '');

      if (title.isEmpty) return;

      if (isScheduled && scheduledTimestampMs != null) {
        await _scheduleLocalFromPayload({
          'title': title,
          'body': body,
          'route': route,
          'scheduledTimestampMs': scheduledTimestampMs.toString(),
          'notifId': notifId.hashCode.toString(),
          'notificationId': notifId,
        });
      } else {
        await _showLocalNow(
          id: notifId.hashCode,
          title: title,
          body: body,
          route: route,
        );
        _addToInbox(InboxNotificationModel(
          id: notifId,
          title: title,
          body: body,
          imageUrl: data['imageUrl'] as String?,
          route: route,
          receivedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('[BroadcastSync] _processBroadcastData error: $e');
    }
  }

  // ─── Inbox Management ────────────────────────────────────────────────────

  void _loadInboxFromStorage() {
    final raw = _storage.read<List<dynamic>>(_kInboxKey);
    if (raw != null) {
      inbox.assignAll(
        raw
            .map((e) =>
                InboxNotificationModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }
    _recalcUnread();
  }

  void _addToInbox(InboxNotificationModel item) {
    inbox.removeWhere((n) => n.id == item.id);
    inbox.insert(0, item);
    if (inbox.length > 100) inbox.removeRange(100, inbox.length);
    _persistInbox();
    _recalcUnread();
  }

  void markRead(String id) {
    final idx = inbox.indexWhere((n) => n.id == id);
    if (idx != -1) {
      inbox[idx] = inbox[idx].copyWith(isRead: true);
      inbox.refresh();
      _persistInbox();
      _recalcUnread();
      recordOpenedReceipt(id);
    }
  }

  void markAllRead() {
    inbox.assignAll(inbox.map((n) => n.copyWith(isRead: true)).toList());
    _persistInbox();
    _recalcUnread();
  }

  void deleteNotification(String id) {
    inbox.removeWhere((n) => n.id == id);
    _persistInbox();
    _recalcUnread();
  }

  void _markReadByRoute(String route) {
    bool changed = false;
    for (int i = 0; i < inbox.length; i++) {
      if (inbox[i].route == route && !inbox[i].isRead) {
        inbox[i] = inbox[i].copyWith(isRead: true);
        changed = true;
        recordOpenedReceipt(inbox[i].id);
      }
    }
    if (changed) {
      inbox.refresh();
      _persistInbox();
      _recalcUnread();
    }
  }

  void _persistInbox() {
    _storage.write(_kInboxKey, inbox.map((n) => n.toMap()).toList());
  }

  void _recalcUnread() {
    unreadCount.value = inbox.where((n) => !n.isRead).length;
  }

  // ─── Delivery & Opened Receipts ──────────────────────────────────────────

  Future<void> recordDeliveryReceipt(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      final deviceId = Get.isRegistered<DeviceIdentityService>()
          ? DeviceIdentityService.to.deviceId
          : '';
      if (deviceId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .collection('recipients')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'deliveredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[NotificationService] Delivery receipt recorded for $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] recordDeliveryReceipt notice: $e');
    }
  }

  Future<void> recordOpenedReceipt(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      final deviceId = Get.isRegistered<DeviceIdentityService>()
          ? DeviceIdentityService.to.deviceId
          : '';
      if (deviceId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .collection('recipients')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'openedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[NotificationService] Opened receipt recorded for $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] recordOpenedReceipt notice: $e');
    }
  }
}
