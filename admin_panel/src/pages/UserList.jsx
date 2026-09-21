import React, { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, onSnapshot } from 'firebase/firestore';
import {
  Search,
  Download,
  Smartphone,
  CheckCircle2,
  XCircle,
  Copy,
  ExternalLink,
  Send,
  X,
  Flame,
  Award,
  Zap,
} from 'lucide-react';
import { db } from '../firebase';

export default function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [platformFilter, setPlatformFilter] = useState('all');
  const [languageFilter, setLanguageFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState(null);
  const [copiedId, setCopiedId] = useState(false);

  const navigate = useNavigate();

  useEffect(() => {
    const usersRef = collection(db, 'users');
    const unsub = onSnapshot(
      usersRef,
      (snapshot) => {
        const list = [];
        snapshot.forEach((doc) => {
          list.push({ id: doc.id, ...doc.data() });
        });
        setUsers(list);
        setLoading(false);
      },
      (err) => {
        console.warn('Firestore users listener error:', err.message);
        setLoading(false);
      }
    );
    return () => unsub();
  }, []);

  // Filter logic
  const filteredUsers = useMemo(() => {
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;

    return users.filter((u) => {
      // Search
      const term = search.toLowerCase().trim();
      const devId = (u.deviceId || u.id || '').toLowerCase();
      if (term && !devId.includes(term)) return false;

      // Platform
      if (platformFilter !== 'all' && (u.platform || '').toLowerCase() !== platformFilter) {
        return false;
      }

      // Language
      if (languageFilter !== 'all' && !(u.language || '').toLowerCase().startsWith(languageFilter)) {
        return false;
      }

      // Status
      const t = u.lastActiveAt?.toMillis ? u.lastActiveAt.toMillis() : (u.lastActiveAt ? new Date(u.lastActiveAt).getTime() : 0);
      if (statusFilter === 'active7d' && (now - t > 7 * dayMs)) return false;
      if (statusFilter === 'inactive7d' && (now - t <= 7 * dayMs)) return false;
      if (statusFilter === 'hasToken' && !u.fcmToken) return false;

      return true;
    });
  }, [users, search, platformFilter, languageFilter, statusFilter]);

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    setCopiedId(true);
    setTimeout(() => setCopiedId(false), 2000);
  };

  const exportCSV = () => {
    if (filteredUsers.length === 0) return;
    const headers = ['DeviceId', 'Platform', 'Language', 'AppVersion', 'Streak', 'TotalDeeds', 'TotalXP', 'HasFCM', 'CreatedAt', 'LastActiveAt'];
    const rows = filteredUsers.map((u) => [
      `"${u.deviceId || u.id}"`,
      `"${u.platform || ''}"`,
      `"${u.language || ''}"`,
      `"${u.appVersion || ''}"`,
      u.stats?.streak || 0,
      u.stats?.totalDeeds || 0,
      u.stats?.totalXp || 0,
      u.fcmToken ? 'YES' : 'NO',
      `"${u.createdAt?.toDate ? u.createdAt.toDate().toISOString() : u.createdAt || ''}"`,
      `"${u.lastActiveAt?.toDate ? u.lastActiveAt.toDate().toISOString() : u.lastActiveAt || ''}"`,
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `deenflow_users_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Anonymous Devices</h1>
          <p className="page-sub">
            Fleet directory of anonymous installations, app telemetry and push tokens
          </p>
        </div>
        <button className="btn btn-ghost" onClick={exportCSV} disabled={filteredUsers.length === 0}>
          <Download size={15} />
          <span>Export CSV</span>
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="card mb-4" style={{ padding: 16 }}>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div className="search-input" style={{ flex: 1, minWidth: 260 }}>
            <Search size={15} className="search-icon" />
            <input
              type="text"
              className="input"
              placeholder="Search by UUID / Device ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <select
              className="select"
              value={platformFilter}
              onChange={(e) => setPlatformFilter(e.target.value)}
              style={{ width: 'auto', padding: '8px 12px', fontSize: 13 }}
            >
              <option value="all">All Platforms</option>
              <option value="android">Android</option>
              <option value="ios">iOS</option>
            </select>

            <select
              className="select"
              value={languageFilter}
              onChange={(e) => setLanguageFilter(e.target.value)}
              style={{ width: 'auto', padding: '8px 12px', fontSize: 13 }}
            >
              <option value="all">All Languages</option>
              <option value="bn">Bengali (bn)</option>
              <option value="en">English (en)</option>
            </select>

            <select
              className="select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              style={{ width: 'auto', padding: '8px 12px', fontSize: 13 }}
            >
              <option value="all">All Activity</option>
              <option value="active7d">Active (≤ 7 days)</option>
              <option value="inactive7d">Inactive (&gt; 7 days)</option>
              <option value="hasToken">Has FCM Token</option>
            </select>
          </div>
        </div>

        <div style={{ marginTop: 12, fontSize: 12, color: 'var(--text-2)', display: 'flex', justifyContent: 'space-between' }}>
          <span>Showing {filteredUsers.length} of {users.length} registered devices</span>
          {(platformFilter !== 'all' || languageFilter !== 'all' || statusFilter !== 'all' || search) && (
            <button
              style={{ background: 'none', border: 'none', color: 'var(--green)', cursor: 'pointer', fontSize: 12 }}
              onClick={() => {
                setSearch('');
                setPlatformFilter('all');
                setLanguageFilter('all');
                setStatusFilter('all');
              }}
            >
              Clear filters
            </button>
          )}
        </div>
      </div>

      {/* Users Table */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div className="center" style={{ padding: 60 }}>
            <div className="spinner" />
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="empty">
            <Smartphone size={32} />
            <p>No matching devices found</p>
          </div>
        ) : (
          <div className="table-wrap" style={{ border: 'none' }}>
            <table>
              <thead>
                <tr>
                  <th>Device ID</th>
                  <th>Platform</th>
                  <th>Lang</th>
                  <th>App Ver</th>
                  <th>Streak</th>
                  <th>Deeds</th>
                  <th>FCM Token</th>
                  <th>Last Active</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((u) => {
                  const lastActive = u.lastActiveAt?.toDate
                    ? u.lastActiveAt.toDate().toLocaleDateString()
                    : (u.lastActiveAt ? new Date(u.lastActiveAt).toLocaleDateString() : 'N/A');

                  return (
                    <tr
                      key={u.id}
                      style={{ cursor: 'pointer' }}
                      onClick={() => setSelectedUser(u)}
                    >
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <code style={{ fontSize: 12, color: 'var(--green)' }}>
                            {(u.deviceId || u.id).slice(0, 16)}...
                          </code>
                        </div>
                      </td>
                      <td>
                        <span className="badge badge-gray">{u.platform || 'unknown'}</span>
                      </td>
                      <td>
                        <span className="badge badge-green">{(u.language || 'en').toUpperCase()}</span>
                      </td>
                      <td>{u.appVersion || '1.0.0'}</td>
                      <td>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--warning)', fontSize: 12 }}>
                          <Flame size={13} /> {u.stats?.streak || 0}d
                        </span>
                      </td>
                      <td>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--green)', fontSize: 12 }}>
                          <Award size={13} /> {u.stats?.totalDeeds || 0}
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
                      <td>
                        <button
                          className="btn btn-ghost btn-sm"
                          onClick={(e) => {
                            e.stopPropagation();
                            navigate('/send', { state: { targetDeviceId: u.deviceId || u.id } });
                          }}
                        >
                          <Send size={12} />
                          <span>Direct</span>
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* User Detail Drawer / Modal */}
      {selectedUser && (
        <div className="modal-overlay" onClick={() => setSelectedUser(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 520 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <div>
                <h3 className="modal-title" style={{ margin: 0 }}>Device Details</h3>
                <span style={{ fontSize: 11, color: 'var(--text-2)' }}>Anonymous Client Profile</span>
              </div>
              <button className="btn btn-ghost btn-icon" onClick={() => setSelectedUser(null)}>
                <X size={18} />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block', marginBottom: 4 }}>DEVICE UUID</span>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <code style={{ fontSize: 12, color: 'var(--green)', wordBreak: 'break-all' }}>
                    {selectedUser.deviceId || selectedUser.id}
                  </code>
                  <button
                    className="btn btn-ghost btn-sm"
                    style={{ marginLeft: 8 }}
                    onClick={() => copyToClipboard(selectedUser.deviceId || selectedUser.id)}
                  >
                    <Copy size={13} />
                    <span>{copiedId ? 'Copied' : 'Copy'}</span>
                  </button>
                </div>
              </div>

              <div className="grid-2" style={{ gap: 12 }}>
                <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)' }}>PLATFORM</span>
                  <div style={{ fontSize: 13, fontWeight: 700, marginTop: 4 }}>{selectedUser.platform || 'Unknown'}</div>
                </div>

                <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)' }}>LANGUAGE</span>
                  <div style={{ fontSize: 13, fontWeight: 700, marginTop: 4 }}>{(selectedUser.language || 'en').toUpperCase()}</div>
                </div>

                <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)' }}>APP VERSION</span>
                  <div style={{ fontSize: 13, fontWeight: 700, marginTop: 4 }}>{selectedUser.appVersion || '1.0.0'}</div>
                </div>

                <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)' }}>NOTIFICATIONS</span>
                  <div style={{ fontSize: 13, fontWeight: 700, marginTop: 4 }}>
                    {selectedUser.notificationsEnabled !== false ? 'Enabled' : 'Disabled'}
                  </div>
                </div>
              </div>

              {/* Gamification Stats */}
              <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block', marginBottom: 8 }}>ISLAMIC HABIT TELEMETRY</span>
                <div style={{ display: 'flex', justifyContent: 'space-around', textAlign: 'center' }}>
                  <div>
                    <div style={{ fontSize: 18, fontWeight: 800, color: 'var(--warning)' }}>
                      🔥 {selectedUser.stats?.streak || 0}
                    </div>
                    <div style={{ fontSize: 10, color: 'var(--text-2)' }}>Day Streak</div>
                  </div>
                  <div>
                    <div style={{ fontSize: 18, fontWeight: 800, color: 'var(--green)' }}>
                      ✨ {selectedUser.stats?.totalDeeds || 0}
                    </div>
                    <div style={{ fontSize: 10, color: 'var(--text-2)' }}>Deeds Completed</div>
                  </div>
                  <div>
                    <div style={{ fontSize: 18, fontWeight: 800, color: '#00d2ff' }}>
                      ⚡ {selectedUser.stats?.totalXp || 0}
                    </div>
                    <div style={{ fontSize: 10, color: 'var(--text-2)' }}>Total XP</div>
                  </div>
                </div>
              </div>

              {/* FCM Token Info */}
              <div style={{ background: 'var(--surface-2)', padding: 12, borderRadius: 8, border: '1px solid var(--border)' }}>
                <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block', marginBottom: 4 }}>FCM TOKEN</span>
                <code style={{ fontSize: 11, color: 'var(--text-2)', wordBreak: 'break-all', display: 'block' }}>
                  {selectedUser.fcmToken || 'No token registered (Permissions not granted or simulator)'}
                </code>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 20 }}>
              <button className="btn btn-ghost" onClick={() => setSelectedUser(null)}>
                Close
              </button>
              <button
                className="btn btn-primary"
                onClick={() => {
                  const devId = selectedUser.deviceId || selectedUser.id;
                  setSelectedUser(null);
                  navigate('/send', { state: { targetDeviceId: devId } });
                }}
              >
                <Send size={14} />
                <span>Send Direct Notification</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
