import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/notifications/models/inbox_notification_model.dart';
import 'device_identity_service.dart';
import 'storage_service.dart';

const String _kInboxKey = 'local_notification_inbox';
const String _kAndroidChannelId = 'deenflow_notifications';
const String _kAndroidChannelName = 'DeenFlow Reminders';

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
      importance: Importance.high,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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

    if (type == 'schedule_local') {
      await _scheduleLocalFromPayload(data);
    } else if (type == 'cancel_schedule') {
      final notifId = int.tryParse(data['notifId'] ?? '');
      if (notifId != null) await _localNotifications.cancel(id: notifId);
    } else {
      final notification = message.notification;
      final title = notification?.title ?? data['title'] ?? '';
      final body = notification?.body ?? data['body'] ?? '';
      final route = data['route'] as String?;

      if (title.isNotEmpty) {
        await _showLocalNow(
          id: message.messageId.hashCode,
          title: title,
          body: body,
          route: route,
        );
        _addToInbox(InboxNotificationModel(
          id: message.messageId ?? DateTime.now().toIso8601String(),
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
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _iosDetails = DarwinNotificationDetails();
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
      final timestampMs = int.tryParse(data['scheduledTimestampMs'] ?? '') ?? 0;
      final notifId = int.tryParse(data['notifId'] ?? '0') ?? 0;

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

      _addToInbox(InboxNotificationModel(
        id: notifId.toString(),
        title: title,
        body: body,
        route: route,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      ));
    } catch (e) {
      debugPrint('[FCM] _scheduleLocalFromPayload error: $e');
    }
  }

  // ─── Free-Tier Firestore Live Broadcast Sync ──────────────────────────────

  void _initBroadcastSync() {
    if (Firebase.apps.isEmpty) return;

    try {
      FirebaseFirestore.instance
          .collection('notifications_broadcast')
          .snapshots()
          .listen((snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            await _processBroadcastDoc(change.doc);
          }
        }
      }, onError: (e) {
        debugPrint('[BroadcastSync] Error listening: $e');
      });
    } catch (e) {
      debugPrint('[BroadcastSync] Init error: $e');
    }
  }

  Future<void> _processBroadcastDoc(DocumentSnapshot doc) async {
    try {
      final docId = doc.id;
      final processed = List<String>.from(
        _storage.read<List<dynamic>>('processed_broadcasts') ?? <String>[],
      );
      if (processed.contains(docId)) return;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

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
      }

      // Mark as processed so it never triggers duplicate notifications
      processed.add(docId);
      if (processed.length > 200) processed.removeRange(0, processed.length - 200);
      _storage.write('processed_broadcasts', processed);

      final title = data['title'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final route = data['route'] as String?;
      final isScheduled = data['isScheduled'] as bool? ?? false;
      final scheduledTimestampMs = data['scheduledTimestampMs'] as int?;

      if (title.isEmpty) return;

      if (isScheduled && scheduledTimestampMs != null) {
        await _scheduleLocalFromPayload({
          'title': title,
          'body': body,
          'route': route,
          'scheduledTimestampMs': scheduledTimestampMs.toString(),
          'notifId': docId.hashCode.toString(),
        });
      } else {
        await _showLocalNow(
          id: docId.hashCode,
          title: title,
          body: body,
          route: route,
        );
        _addToInbox(InboxNotificationModel(
          id: docId,
          title: title,
          body: body,
          imageUrl: data['imageUrl'] as String?,
          route: route,
          receivedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('[BroadcastSync] _processBroadcastDoc error: $e');
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
}
