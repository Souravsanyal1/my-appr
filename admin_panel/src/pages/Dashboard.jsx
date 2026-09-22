import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  limit,
} from 'firebase/firestore';
import {
  Users,
  Smartphone,
  Globe,
  Bell,
  Activity,
  Send,
  ArrowUpRight,
  ShieldCheck,
  CheckCircle2,
} from 'lucide-react';
import { db } from '../firebase';
import StatCard from '../components/StatCard';

export default function Dashboard() {
  const [users, setUsers] = useState([]);
  const [notificationsCount, setNotificationsCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Listen to users collection
    const usersRef = collection(db, 'users');
    const unsubUsers = onSnapshot(
      usersRef,
      (snapshot) => {
        const userList = [];
        snapshot.forEach((doc) => {
          userList.push({ id: doc.id, ...doc.data() });
        });
        setUsers(userList);
        setLoading(false);
      },
      (error) => {
        console.warn('Firestore users listener (falling back to initial view):', error.message);
        setLoading(false);
      }
    );

    // Listen to notifications log count
    const notifRef = collection(db, 'notifications_log');
    const unsubNotifs = onSnapshot(
      notifRef,
      (snapshot) => {
        setNotificationsCount(snapshot.size);
      },
      (err) => console.warn('Firestore notifications listener:', err.message)
    );

    return () => {
      unsubUsers();
      unsubNotifs();
    };
  }, []);

  // Compute metrics
  const totalUsers = users.length;
  const now = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;

  const active24h = users.filter((u) => {
    const t = u.lastActiveAt?.toMillis ? u.lastActiveAt.toMillis() : (u.lastActiveAt ? new Date(u.lastActiveAt).getTime() : 0);
    return now - t <= dayMs;
  }).length;

  const active7d = users.filter((u) => {
    const t = u.lastActiveAt?.toMillis ? u.lastActiveAt.toMillis() : (u.lastActiveAt ? new Date(u.lastActiveAt).getTime() : 0);
    return now - t <= 7 * dayMs;
  }).length;

  const androidCount = users.filter((u) => (u.platform || '').toLowerCase() === 'android').length;
  const iosCount = users.filter((u) => (u.platform || '').toLowerCase() === 'ios').length;

  const bnCount = users.filter((u) => (u.language || '').toLowerCase().startsWith('bn')).length;
  const enCount = users.filter((u) => (u.language || '').toLowerCase().startsWith('en')).length;

  const notifEnabledCount = users.filter((u) => u.notificationsEnabled !== false && u.fcmToken).length;

  return (
    <div>
      {/* Top Banner / Actions */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Overview Dashboard</h1>
          <p className="page-sub">
            Anonymous fleet analytics, real-time device activity and push infrastructure
          </p>
        </div>
        <button
          className="btn btn-primary"
          onClick={() => navigate('/send')}
        >
          <Send size={15} />
          <span>New Notification</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="stat-grid">
        <StatCard
          label="TOTAL ANONYMOUS DEVICES"
          value={loading ? '...' : totalUsers}
          sub="No login required"
          icon={Users}
          accentColor="var(--green)"
        />
        <StatCard
          label="ACTIVE IN LAST 24H"
          value={loading ? '...' : active24h}
          sub={totalUsers > 0 ? `${Math.round((active24h / totalUsers) * 100)}% of device fleet` : '0%'}
          icon={Activity}
          accentColor="#00d2ff"
        />
        <StatCard
          label="ACTIVE IN LAST 7 DAYS"
          value={loading ? '...' : active7d}
          sub="Weekly active devices"
          icon={CheckCircle2}
          accentColor="#a855f7"
        />
        <StatCard
          label="FCM PUSH REACHABLE"
          value={loading ? '...' : notifEnabledCount}
          sub="Active tokens registered"
          icon={Bell}
          accentColor="var(--warning)"
        />
      </div>

      {/* Breakdown Section */}
      <div className="grid-2 mt-6">
        {/* Platform Breakdown */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: 'var(--text)' }}>Platform Distribution</h3>
            <Smartphone size={16} color="var(--text-2)" />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 6 }}>
                <span>Android</span>
                <strong>{androidCount} ({totalUsers ? Math.round((androidCount / totalUsers) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: 8, background: 'var(--surface-2)', borderRadius: 4, overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    background: 'var(--green)',
                    width: `${totalUsers ? (androidCount / totalUsers) * 100 : 0}%`,
                    borderRadius: 4,
                    transition: 'width 0.5s ease',
                  }}
                />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 6 }}>
                <span>iOS</span>
                <strong>{iosCount} ({totalUsers ? Math.round((iosCount / totalUsers) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: 8, background: 'var(--surface-2)', borderRadius: 4, overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    background: '#00d2ff',
                    width: `${totalUsers ? (iosCount / totalUsers) * 100 : 0}%`,
                    borderRadius: 4,
                    transition: 'width 0.5s ease',
                  }}
                />
              </div>
            </div>
          </div>

          <div className="divider" />
          <div style={{ fontSize: 11, color: 'var(--text-2)', display: 'flex', gap: 6, alignItems: 'center' }}>
            <ShieldCheck size={14} color="var(--green)" />
            <span>Targeting supported for Android & iOS independently</span>
          </div>
        </div>

        {/* Language Breakdown */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: 'var(--text)' }}>Language Preference</h3>
            <Globe size={16} color="var(--text-2)" />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 6 }}>
                <span>Bengali (bn)</span>
                <strong>{bnCount} ({totalUsers ? Math.round((bnCount / totalUsers) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: 8, background: 'var(--surface-2)', borderRadius: 4, overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    background: 'var(--green)',
                    width: `${totalUsers ? (bnCount / totalUsers) * 100 : 0}%`,
                    borderRadius: 4,
                    transition: 'width 0.5s ease',
                  }}
                />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 6 }}>
                <span>English (en)</span>
                <strong>{enCount} ({totalUsers ? Math.round((enCount / totalUsers) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: 8, background: 'var(--surface-2)', borderRadius: 4, overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    background: '#a855f7',
                    width: `${totalUsers ? (enCount / totalUsers) * 100 : 0}%`,
                    borderRadius: 4,
                    transition: 'width 0.5s ease',
                  }}
                />
              </div>
            </div>
          </div>

          <div className="divider" />
          <div style={{ fontSize: 11, color: 'var(--text-2)', display: 'flex', gap: 6, alignItems: 'center' }}>
            <Globe size={14} color="var(--green)" />
            <span>Target localized notifications by user device language</span>
          </div>
        </div>
      </div>

      {/* Recent Devices Quick Table */}
      <div className="card mt-6">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: 'var(--text)' }}>Recently Active Devices</h3>
            <p style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 2 }}>Latest registered anonymous client nodes</p>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={() => navigate('/users')}>
            <span>View All Devices</span>
            <ArrowUpRight size={13} />
          </button>
        </div>

        {users.length === 0 ? (
          <div className="empty">
            <Smartphone size={32} />
            <p>No devices recorded yet. Launch the mobile app to sync first client!</p>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Device ID</th>
                  <th>Platform</th>
                  <th>Language</th>
                  <th>App Ver</th>
                  <th>Streak / Deeds</th>
                  <th>FCM Token</th>
                  <th>Last Active</th>
                </tr>
              </thead>
              <tbody>
                {users.slice(0, 5).map((u) => {
                  const lastActive = u.lastActiveAt?.toDate
                    ? u.lastActiveAt.toDate().toLocaleString()
                    : (u.lastActiveAt ? new Date(u.lastActiveAt).toLocaleString() : 'Just now');

                  return (
                    <tr key={u.id}>
                      <td>
                        <code style={{ fontSize: 11, color: 'var(--green)' }}>{u.deviceId || u.id}</code>
                      </td>
                      <td>
                        <span className="badge badge-gray">{u.platform || 'Unknown'}</span>
                      </td>
                      <td>
                        <span className="badge badge-green">{(u.language || 'en').toUpperCase()}</span>
                      </td>
                      <td>{u.appVersion || '1.0.0'}</td>
                      <td>
                        <span style={{ fontSize: 11, color: 'var(--text-2)' }}>
                          🔥 {u.stats?.streak || 0}d | ✨ {u.stats?.totalDeeds || 0}
                        </span>
                      </td>
                      <td>
                        {u.fcmToken ? (
                          <span className="badge badge-green">Registered</span>
                        ) : (
                          <span className="badge badge-red">Missing</span>
                        )}
                      </td>
                      <td style={{ fontSize: 11, color: 'var(--text-2)' }}>{lastActive}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
