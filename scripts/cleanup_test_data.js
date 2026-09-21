/**
 * FocusDeen Test / Demo Data Cleanup Utility
 * 
 * Safely removes test documents and demo entries from both
 * Cloud Firestore and Realtime Database after explicit confirmation.
 * 
 * Usage:
 *   node scripts/cleanup_test_data.js
 */

const readline = require('readline');
const admin = require('firebase-admin');

// Initialize Firebase Admin with default app or environment credentials
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: 'focusdeen-f8295',
    databaseURL: 'https://focusdeen-f8295-default-rtdb.asia-southeast1.firebasedatabase.app',
  });
}

const firestore = admin.firestore();
const rtdb = admin.database();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

async function main() {
  console.log('\n======================================================');
  console.log('       FocusDeen Test / Demo Data Cleanup Tool        ');
  console.log('       Project: focusdeen-f8295                       ');
  console.log('======================================================\n');

  console.log('Scanning for demo and test records in Firestore & RTDB...\n');

  // 1. Scan Firestore users
  const usersSnap = await firestore.collection('users').get();
  const testUsers = [];
  usersSnap.forEach((doc) => {
    const data = doc.data();
    const id = doc.id.toLowerCase();
    const isMock =
      id.includes('test') ||
      id.includes('demo') ||
      id.includes('mock') ||
      id.includes('sample') ||
      data.isTestUser === true ||
      data.deviceId?.includes('test');
    if (isMock) {
      testUsers.push({ id: doc.id, data });
    }
  });

  // 2. Scan notifications
  const notifsSnap = await firestore.collection('notifications').get();
  const testNotifs = [];
  notifsSnap.forEach((doc) => {
    const data = doc.data();
    const title = (data.title || '').toLowerCase();
    if (title.includes('test') || title.includes('demo') || title.includes('sample')) {
      testNotifs.push({ id: doc.id, data });
    }
  });

  // 3. Scan legacy notifications_log
  const legacySnap = await firestore.collection('notifications_log').get();
  const testLegacyNotifs = [];
  legacySnap.forEach((doc) => {
    const data = doc.data();
    const title = (data.title || '').toLowerCase();
    if (title.includes('test') || title.includes('demo') || title.includes('sample')) {
      testLegacyNotifs.push({ id: doc.id, data });
    }
  });

  console.log(`Found ${testUsers.length} test user documents in Firestore.`);
  console.log(`Found ${testNotifs.length} test notifications in Firestore.`);
  console.log(`Found ${testLegacyNotifs.length} test legacy notifications in Firestore.\n`);

  if (testUsers.length === 0 && testNotifs.length === 0 && testLegacyNotifs.length === 0) {
    console.log('✅ No obvious test documents found. Your database is clean!\n');
    rl.close();
    return;
  }

  console.log('Test Users identified:');
  testUsers.forEach((u) => console.log(`  - [User] ${u.id} (${u.data.platform || 'N/A'})`));

  console.log('\nTest Notifications identified:');
  testNotifs.forEach((n) => console.log(`  - [Notif] ${n.id} : "${n.data.title}"`));
  testLegacyNotifs.forEach((n) => console.log(`  - [Legacy] ${n.id} : "${n.data.title}"`));

  console.log('\n⚠️  WARNING: This action is permanent and cannot be undone.');
  rl.question('\nType "DELETE" to confirm deletion of the above test records: ', async (answer) => {
    if (answer.trim() !== 'DELETE') {
      console.log('\n❌ Operation cancelled by user. No records were deleted.\n');
      rl.close();
      return;
    }

    console.log('\nDeleting test records...');

    // Delete test users
    for (const u of testUsers) {
      await firestore.collection('users').doc(u.id).delete();
      // Clean up RTDB presence & unlockState
      await rtdb.ref(`presence/${u.id}`).remove();
      await rtdb.ref(`unlockState/${u.id}`).remove();
      console.log(`  Deleted user: ${u.id}`);
    }

    // Delete test notifications
    for (const n of testNotifs) {
      await firestore.collection('notifications').doc(n.id).delete();
      console.log(`  Deleted notification: ${n.id}`);
    }

    for (const n of testLegacyNotifs) {
      await firestore.collection('notifications_log').doc(n.id).delete();
      console.log(`  Deleted legacy notification: ${n.id}`);
    }

    // Re-sync liveStats/totalUsers in RTDB to match real non-test user count
    const remainingUsersSnap = await firestore.collection('users').get();
    await rtdb.ref('liveStats/totalUsers').set(remainingUsersSnap.size);

    console.log('\n✅ Cleanup complete. RTDB liveStats/totalUsers re-synchronized to current real user count.\n');
    rl.close();
  });
}

main().catch((err) => {
  console.error('\nError running cleanup script:', err);
  rl.close();
  process.exit(1);
});
