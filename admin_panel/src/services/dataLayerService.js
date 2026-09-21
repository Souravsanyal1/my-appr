import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  serverTimestamp,
} from 'firebase/firestore';
import {
  ref,
  onValue,
  get,
  set,
  remove,
  serverTimestamp as rtdbServerTimestamp,
} from 'firebase/database';
import { db, rtdb } from '../firebase';

/**
 * DataLayerService - Centralized data access for FocusDeen Admin Panel.
 * Splits live ephemeral counters to Realtime Database and queryable permanent
 * records to Cloud Firestore.
 */
class DataLayerService {
  // ═══════════════════════════════════════════════════════════════
  // 1. REALTIME DATABASE: LIVE STATS & COUNTERS
  // ═══════════════════════════════════════════════════════════════

  /**
   * Listen to liveStats in RTDB: totalUsers, onlineNow, activeToday, deedsCompletedToday
   */
  subscribeLiveStats(callback) {
    const statsRef = ref(rtdb, 'liveStats');
    return onValue(
      statsRef,
      (snapshot) => {
        const data = snapshot.val() || {};
        callback({
          totalUsers: data.totalUsers || 0,
          onlineNow: data.onlineNow || 0,
          activeToday: data.activeToday || 0,
          deedsCompletedToday: data.deedsCompletedToday || 0,
        });
      },
      (error) => {
        console.warn('[DataLayer] RTDB liveStats listener error:', error.message);
        callback({
          totalUsers: 0,
          onlineNow: 0,
          activeToday: 0,
          deedsCompletedToday: 0,
        });
      }
    );
  }

  /**
   * Listen to device presence list in RTDB: { [deviceId]: { online: boolean, lastSeen: number } }
   */
  subscribePresence(callback) {
    const presenceRef = ref(rtdb, 'presence');
    return onValue(
      presenceRef,
      (snapshot) => {
        const data = snapshot.val() || {};
        callback(data);
      },
      (error) => {
        console.warn('[DataLayer] RTDB presence listener error:', error.message);
        callback({});
      }
    );
  }

  /**
   * Get single device presence state from RTDB
   */
  async getDevicePresence(deviceId) {
    try {
      const snap = await get(ref(rtdb, `presence/${deviceId}`));
      return snap.val() || { online: false, lastSeen: null };
    } catch (err) {
      console.warn('[DataLayer] getDevicePresence error:', err);
      return { online: false, lastSeen: null };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. FIRESTORE: USER FLEET & PROFILES (users/{deviceId})
  // ═══════════════════════════════════════════════════════════════

  /**
   * Real-time subscription to full users collection in Firestore
   */
  subscribeUsers(callback) {
    const usersRef = collection(db, 'users');
    return onSnapshot(
      usersRef,
      (snapshot) => {
        const userList = [];
        snapshot.forEach((docSnap) => {
          userList.push({
            id: docSnap.id,
            ...docSnap.data(),
          });
        });
        callback(userList);
      },
      (error) => {
        console.warn('[DataLayer] Firestore users listener error:', error.message);
        callback([]);
      }
    );
  }

  /**
   * Get single user full profile from Firestore
   */
  async getUserDetail(deviceId) {
    try {
      const docSnap = await getDoc(doc(db, 'users', deviceId));
      if (!docSnap.exists()) return null;
      return {
        id: docSnap.id,
        ...docSnap.data(),
      };
    } catch (err) {
      console.error('[DataLayer] getUserDetail error:', err);
      throw err;
    }
  }

  /**
   * Delete user from Firestore (Cloud Function will atomically decrement RTDB totalUsers)
   */
  async deleteUser(deviceId) {
    try {
      await deleteDoc(doc(db, 'users', deviceId));
      // Also clean up presence in RTDB
      await remove(ref(rtdb, `presence/${deviceId}`));
      await remove(ref(rtdb, `unlockState/${deviceId}`));
      return true;
    } catch (err) {
      console.error('[DataLayer] deleteUser error:', err);
      throw err;
    }
  }

  /**
   * Query deed history items for a specific device: deedHistory/{deviceId}/items
   */
  async getDeedHistory(deviceId, maxCount = 50) {
    try {
      const itemsRef = collection(db, 'deedHistory', deviceId, 'items');
      const q = query(itemsRef, orderBy('completedAt', 'desc'), limit(maxCount));
      const snap = await getDocs(q);
      const list = [];
      snap.forEach((d) => list.push({ id: d.id, ...d.data() }));
      return list;
    } catch (err) {
      console.warn('[DataLayer] getDeedHistory notice:', err.message);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. FIRESTORE: NOTIFICATIONS (notifications/{id})
  // ═══════════════════════════════════════════════════════════════

  /**
   * Real-time subscription to notifications history
   */
  subscribeNotifications(callback, maxCount = 50) {
    const notifRef = collection(db, 'notifications');
    const q = query(notifRef, orderBy('createdAt', 'desc'), limit(maxCount));
    return onSnapshot(
      q,
      (snapshot) => {
        const list = [];
        snapshot.forEach((docSnap) => {
          list.push({ id: docSnap.id, ...docSnap.data() });
        });
        callback(list);
      },
      (error) => {
        console.warn('[DataLayer] Firestore notifications listener fallback:', error.message);
        // Fallback to legacy notifications_log if notifications collection is empty
        const legacyRef = collection(db, 'notifications_log');
        return onSnapshot(legacyRef, (legSnap) => {
          const legList = [];
          legSnap.forEach((d) => legList.push({ id: d.id, ...d.data() }));
          callback(legList);
        });
      }
    );
  }

  /**
   * Record dispatched notification record in Firestore
   */
  async recordNotification(notificationData) {
    try {
      const colRef = collection(db, 'notifications');
      const docRef = doc(colRef);
      await setDoc(docRef, {
        ...notificationData,
        createdAt: serverTimestamp(),
      });
      return docRef.id;
    } catch (err) {
      console.error('[DataLayer] recordNotification error:', err);
      throw err;
    }
  }
}

export const dataLayer = new DataLayerService();
export default dataLayer;
