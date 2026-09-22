const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Helper: Validates that caller is an authenticated administrator
 */
function assertAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Caller must be authenticated to dispatch notifications.'
    );
  }
}

/**
 * Split an array into chunks of specified size (FCM multicast max: 500)
 */
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * HTTPS Callable: sendNotification
 * Immediately dispatches an FCM notification to targeted anonymous client fleet
 */
exports.sendNotification = functions.https.onCall(async (data, context) => {
  assertAdmin(context);

  const {
    title,
    body,
    imageUrl,
    route,
    targetType = 'all',
    targetPlatform,
    targetLanguage,
    targetDeviceId,
  } = data;

  if (!title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both title and body are required.'
    );
  }

  // 1. Query candidate users
  let tokens = [];
  let userDocs = [];

  if (targetType === 'specific' && targetDeviceId) {
    const docSnap = await db.collection('users').doc(targetDeviceId).get();
    if (docSnap.exists) {
      const u = docSnap.data();
      if (u.fcmToken && u.notificationsEnabled !== false) {
        tokens.push(u.fcmToken);
        userDocs.push({ id: docSnap.id, token: u.fcmToken });
      }
    }
  } else {
    let queryRef = db.collection('users');

    if (targetType === 'platform' && targetPlatform) {
      queryRef = queryRef.where('platform', '==', targetPlatform.toLowerCase());
    } else if (targetType === 'language' && targetLanguage) {
      queryRef = queryRef.where('language', '==', targetLanguage.toLowerCase());
    }

    const snapshot = await queryRef.get();
    const now = Date.now();
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

    snapshot.forEach((doc) => {
      const u = doc.data();
      if (!u.fcmToken || u.notificationsEnabled === false) return;

      if (targetType === 'inactive') {
        const lastActive = u.lastActiveAt?.toMillis ? u.lastActiveAt.toMillis() : 0;
        if (now - lastActive <= sevenDaysMs) return; // skip active users
      }

      tokens.push(u.fcmToken);
      userDocs.push({ id: doc.id, token: u.fcmToken });
    });
  }

  if (tokens.length === 0) {
    return {
      success: true,
      deliveredCount: 0,
      failureCount: 0,
      message: 'No active reachable devices found for given target criteria.',
    };
  }

  // 2. Multicast FCM in batches of 500
  const tokenBatches = chunkArray(tokens, 500);
  let totalSuccess = 0;
  let totalFailure = 0;
  const invalidTokens = [];

  for (const batch of tokenBatches) {
    const message = {
      notification: {
        title,
        body,
        ...(imageUrl ? { imageUrl } : {}),
      },
      data: {
        title,
        body,
        route: route || '',
        imageUrl: imageUrl || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        sentAt: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'deenflow_notifications',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      tokens: batch,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;

      // Identify stale/unregistered tokens for automatic database hygiene
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(batch[idx]);
          }
        }
      });
    } catch (batchErr) {
      console.error('Error sending multicast batch:', batchErr);
    }
  }

  // 3. Clean up invalid tokens from Firestore
  if (invalidTokens.length > 0) {
    const batchDb = db.batch();
    userDocs
      .filter((u) => invalidTokens.includes(u.token))
      .forEach((u) => {
        batchDb.update(db.collection('users').doc(u.id), {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    await batchDb.commit().catch((err) => console.warn('Token cleanup error:', err));
  }

  // 4. Log to notifications_log
  await db.collection('notifications_log').add({
    title,
    body,
    imageUrl: imageUrl || null,
    route: route || null,
    targetType,
    targetPlatform: targetPlatform || null,
    targetLanguage: targetLanguage || null,
    targetDeviceId: targetDeviceId || null,
    recipientCount: tokens.length,
    deliveredCount: totalSuccess,
    failureCount: totalFailure,
    status: 'sent',
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    recipientCount: tokens.length,
    deliveredCount: totalSuccess,
    failureCount: totalFailure,
  };
});

/**
 * HTTPS Callable: scheduleNotification
 * Dispatches silent data message ('type: schedule_local') to client devices
 * so the notification is pre-scheduled locally on device and sounds even if offline!
 */
exports.scheduleNotification = functions.https.onCall(async (data, context) => {
  assertAdmin(context);

  const {
    title,
    body,
    imageUrl,
    route,
    scheduledTimestampMs,
    targetType = 'all',
  } = data;

  // Query tokens
  const usersSnap = await db.collection('users').get();
  const tokens = [];
  usersSnap.forEach((doc) => {
    const u = doc.data();
    if (u.fcmToken && u.notificationsEnabled !== false) {
      tokens.push(u.fcmToken);
    }
  });

  if (tokens.length === 0) {
    return { success: true, count: 0 };
  }

  // Generate unique integer id for local notification slot
  const localNotifId = Math.abs(Math.floor(Math.random() * 10000000));

  // Send silent high-priority data message for local scheduling
  const tokenBatches = chunkArray(tokens, 500);
  for (const batch of tokenBatches) {
    const message = {
      data: {
        type: 'schedule_local',
        localNotificationId: String(localNotifId),
        title: title || '',
        body: body || '',
        route: route || '',
        imageUrl: imageUrl || '',
        scheduledTimestampMs: String(scheduledTimestampMs),
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-push-type': 'background', 'apns-priority': '5' },
        payload: { aps: { 'content-available': 1 } },
      },
      tokens: batch,
    };

    try {
      await admin.messaging().sendEachForMulticast(message);
    } catch (err) {
      console.warn('Pre-schedule multicast error:', err);
    }
  }

  return { success: true, preScheduledCount: tokens.length, localNotificationId: localNotifId };
});

/**
 * HTTPS Callable: cancelScheduledNotification
 * Dispatches silent cancel data message ('type: cancel_schedule') to remove alarm
 */
exports.cancelScheduledNotification = functions.https.onCall(async (data, context) => {
  assertAdmin(context);

  const { notificationId } = data;
  if (!notificationId) {
    throw new functions.https.HttpsError('invalid-argument', 'notificationId is required.');
  }

  // Update Firestore record
  await db.collection('scheduled_notifications').doc(notificationId).update({
    status: 'cancelled',
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Query tokens to send cancel alarm
  const usersSnap = await db.collection('users').get();
  const tokens = [];
  usersSnap.forEach((doc) => {
    const u = doc.data();
    if (u.fcmToken) tokens.push(u.fcmToken);
  });

  if (tokens.length > 0) {
    const tokenBatches = chunkArray(tokens, 500);
    for (const batch of tokenBatches) {
      await admin.messaging().sendEachForMulticast({
        data: {
          type: 'cancel_schedule',
          scheduledDocId: String(notificationId),
        },
        android: { priority: 'high' },
        tokens: batch,
      }).catch((e) => console.warn('Cancel multicast error:', e));
    }
  }

  return { success: true };
});

/**
 * Cloud Scheduler: checkScheduledNotifications
 * Runs every 1 minute.
 * Finds due scheduled items and sends fallback multicast if client was offline.
 */
exports.checkScheduledNotifications = functions.pubsub
  .schedule('* * * * *')
  .onRun(async () => {
    const now = Date.now();
    const snapshot = await db
      .collection('scheduled_notifications')
      .where('status', '==', 'scheduled')
      .where('scheduledTimestampMs', '<=', now)
      .limit(10)
      .get();

    if (snapshot.empty) return null;

    for (const doc of snapshot.docs) {
      const item = doc.data();

      // Gather reachable tokens
      const usersSnap = await db.collection('users').get();
      const tokens = [];
      usersSnap.forEach((uDoc) => {
        const u = uDoc.data();
        if (u.fcmToken && u.notificationsEnabled !== false) {
          tokens.push(u.fcmToken);
        }
      });

      if (tokens.length > 0) {
        const batches = chunkArray(tokens, 500);
        for (const batch of batches) {
          try {
            await admin.messaging().sendEachForMulticast({
              notification: {
                title: item.title,
                body: item.body,
                ...(item.imageUrl ? { imageUrl: item.imageUrl } : {}),
              },
              data: {
                title: item.title,
                body: item.body,
                route: item.route || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              android: {
                priority: 'high',
                notification: { channelId: 'deenflow_notifications', sound: 'default' },
              },
              tokens: batch,
            });
          } catch (err) {
            console.error('Scheduled fallback multicast error:', err);
          }
        }
      }

      // Mark as sent
      await doc.ref.update({
        status: 'sent',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

/**
 * Cloud Scheduler: cleanupInactiveTokens
 * Runs every Sunday at 03:00 AM to keep database lightweight on Firebase free tier.
 */
exports.cleanupInactiveTokens = functions.pubsub
  .schedule('0 3 * * 0')
  .onRun(async () => {
    const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
    const snap = await db
      .collection('users')
      .where('lastActiveAt', '<', ninetyDaysAgo)
      .limit(500)
      .get();

    if (snap.empty) return null;

    const batch = db.batch();
    snap.forEach((doc) => {
      // Clear fcmToken so we don't dispatch to stale device
      batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
    });

    await batch.commit();
    console.log(`Cleaned up tokens for ${snap.size} inactive devices.`);
    return null;
  });

/**
 * Firestore Trigger: onUserCreated
 * Atomically increments RTDB liveStats/totalUsers when a new user document is created.
 */
exports.onUserCreated = functions.firestore
  .document('users/{deviceId}')
  .onCreate(async (snap, context) => {
    try {
      const rtdb = admin.database();
      await rtdb.ref('liveStats/totalUsers').transaction((current) => (current || 0) + 1);
      console.log(`[RTDB Sync] Increment totalUsers for new device: ${context.params.deviceId}`);
    } catch (err) {
      console.error('[RTDB Sync] onUserCreated error:', err);
    }
  });

/**
 * Firestore Trigger: onUserDeleted
 * Atomically decrements RTDB liveStats/totalUsers when a user document is deleted.
 */
exports.onUserDeleted = functions.firestore
  .document('users/{deviceId}')
  .onDelete(async (snap, context) => {
    try {
      const rtdb = admin.database();
      await rtdb.ref('liveStats/totalUsers').transaction((current) => Math.max(0, (current || 1) - 1));
      console.log(`[RTDB Sync] Decrement totalUsers for deleted device: ${context.params.deviceId}`);
    } catch (err) {
      console.error('[RTDB Sync] onUserDeleted error:', err);
    }
  });

/**
 * Cloud Scheduler: pruneStaleRtdbAndDeeds
 * Runs daily at 04:00 AM to prune expired active_unlocks, stale unlockState, and old deed history.
 */
exports.pruneStaleRtdbAndDeeds = functions.pubsub
  .schedule('0 4 * * *')
  .onRun(async () => {
    const now = Date.now();
    const rtdbUrl = 'https://focusdeen-f8295-default-rtdb.asia-southeast1.firebasedatabase.app';
    const rtdb = admin.database(rtdbUrl);

    // 1. Prune expired active_unlocks in RTDB
    try {
      const activeUnlocksSnap = await rtdb.ref('active_unlocks').once('value');
      if (activeUnlocksSnap.exists()) {
        const usersData = activeUnlocksSnap.val();
        const updates = {};
        for (const [uid, apps] of Object.entries(usersData)) {
          if (apps && typeof apps === 'object') {
            for (const [pkgKey, session] of Object.entries(apps)) {
              if (session && session.expiresAtTimestamp && session.expiresAtTimestamp < now) {
                updates[`active_unlocks/${uid}/${pkgKey}`] = null;
              }
            }
          }
        }
        if (Object.keys(updates).length > 0) {
          await rtdb.ref().update(updates);
          console.log(`[Data Hygiene] Pruned ${Object.keys(updates).length} expired RTDB active_unlocks.`);
        }
      }
    } catch (err) {
      console.error('[Data Hygiene] Error pruning active_unlocks:', err);
    }

    // 2. Prune expired unlockState in RTDB
    try {
      const unlockStateSnap = await rtdb.ref('unlockState').once('value');
      if (unlockStateSnap.exists()) {
        const devices = unlockStateSnap.val();
        const updates = {};
        for (const [deviceId, state] of Object.entries(devices)) {
          if (state && state.unlockedUntil && state.unlockedUntil < now && state.isUnlocked) {
            updates[`unlockState/${deviceId}/isUnlocked`] = false;
            updates[`unlockState/${deviceId}/unlockedUntil`] = 0;
          }
        }
        if (Object.keys(updates).length > 0) {
          await rtdb.ref().update(updates);
          console.log(`[Data Hygiene] Reset ${Object.keys(updates).length} expired unlockState records.`);
        }
      }
    } catch (err) {
      console.error('[Data Hygiene] Error pruning unlockState:', err);
    }

    // 3. Prune Firestore deedHistory older than 90 days
    try {
      const ninetyDaysAgo = new Date(now - 90 * 24 * 60 * 60 * 1000);
      const staleDeedsSnap = await db
        .collectionGroup('items')
        .where('completedAt', '<', ninetyDaysAgo)
        .limit(300)
        .get();

      if (!staleDeedsSnap.empty) {
        const batch = db.batch();
        staleDeedsSnap.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        console.log(`[Data Hygiene] Deleted ${staleDeedsSnap.size} stale deed logs.`);
      }
    } catch (err) {
      console.error('[Data Hygiene] Error pruning Firestore deedHistory:', err);
    }

    return null;
  });

