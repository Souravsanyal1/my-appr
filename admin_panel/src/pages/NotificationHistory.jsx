import React, { useState, useEffect } from 'react';
import {
  collection,
  onSnapshot,
  doc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import {
  History,
  Calendar,
  Send,
  Trash2,
  XCircle,
  ExternalLink,
  Users,
  Clock,
  CheckCircle2,
} from 'lucide-react';
import { db, functions } from '../firebase';

export default function NotificationHistory() {
  const [activeTab, setActiveTab] = useState('sent'); // 'sent' | 'scheduled'
  const [sentList, setSentList] = useState([]);
  const [scheduledList, setScheduledList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [cancellingId, setCancellingId] = useState(null);

  useEffect(() => {
    // Listen to sent logs
    const sentRef = collection(db, 'notifications_log');
    const unsubSent = onSnapshot(
      sentRef,
      (snapshot) => {
        const list = [];
        snapshot.forEach((d) => list.push({ id: d.id, ...d.data() }));
        // Sort descending by sentAt/createdAt
        list.sort((a, b) => {
          const ta = a.sentAt?.toMillis ? a.sentAt.toMillis() : (a.createdAt?.toMillis ? a.createdAt.toMillis() : 0);
          const tb = b.sentAt?.toMillis ? b.sentAt.toMillis() : (b.createdAt?.toMillis ? b.createdAt.toMillis() : 0);
          return tb - ta;
        });
        setSentList(list);
        setLoading(false);
      },
      (err) => {
        console.warn('notifications_log listener error:', err.message);
        setLoading(false);
      }
    );

    // Listen to scheduled jobs
    const schedRef = collection(db, 'scheduled_notifications');
    const unsubSched = onSnapshot(
      schedRef,
      (snapshot) => {
        const list = [];
        snapshot.forEach((d) => list.push({ id: d.id, ...d.data() }));
        list.sort((a, b) => (a.scheduledTimestampMs || 0) - (b.scheduledTimestampMs || 0));
        setScheduledList(list);
      },
      (err) => console.warn('scheduled_notifications listener error:', err.message)
    );

    return () => {
      unsubSent();
      unsubSched();
    };
  }, []);

  const handleCancelScheduled = async (id, title) => {
    if (!window.confirm(`Are you sure you want to cancel the scheduled notification "${title}"?`)) {
      return;
    }
    setCancellingId(id);
    try {
      // 1. Update in Firestore
      const docRef = doc(db, 'scheduled_notifications', id);
      await updateDoc(docRef, { status: 'cancelled' });

      // 2. Try calling Cloud Function to dispatch silent cancel alarm to client devices
      try {
        const cancelFn = httpsCallable(functions, 'cancelScheduledNotification');
        await cancelFn({ notificationId: id });
      } catch (fnErr) {
        console.log('Cloud Function callable omitted or pending deployment:', fnErr.message);
      }
    } catch (err) {
      alert('Error cancelling notification: ' + err.message);
    } finally {
      setCancellingId(null);
    }
  };

  const handleDeleteLog = async (id) => {
    if (!window.confirm('Delete this notification log entry?')) return;
    try {
      await deleteDoc(doc(db, 'notifications_log', id));
    } catch (err) {
      alert('Error deleting: ' + err.message);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Notification History & Queue</h1>
          <p className="page-sub">
            Track past broadcast metrics and manage scheduled offline local notifications
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="filter-bar" style={{ marginBottom: 20 }}>
        <button
          className={`filter-chip ${activeTab === 'sent' ? 'active' : ''}`}
          onClick={() => setActiveTab('sent')}
        >
          <Send size={13} style={{ marginRight: 6 }} />
          Sent Broadcasts ({sentList.length})
        </button>
        <button
          className={`filter-chip ${activeTab === 'scheduled' ? 'active' : ''}`}
          onClick={() => setActiveTab('scheduled')}
        >
          <Calendar size={13} style={{ marginRight: 6 }} />
          Scheduled Queue ({scheduledList.filter((s) => s.status === 'scheduled').length})
        </button>
      </div>

      {/* Content */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div className="center" style={{ padding: 60 }}>
            <div className="spinner" />
          </div>
        ) : activeTab === 'sent' ? (
          /* Sent Notifications Table */
          sentList.length === 0 ? (
            <div className="empty">
              <History size={32} />
              <p>No broadcast history recorded yet</p>
            </div>
          ) : (
            <div className="table-wrap" style={{ border: 'none' }}>
              <table>
                <thead>
                  <tr>
                    <th>Title & Content</th>
                    <th>Target Audience</th>
                    <th>Recipients</th>
                    <th>Deep Link</th>
                    <th>Dispatched At</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {sentList.map((item) => {
                    const sentAt = item.sentAt?.toDate
                      ? item.sentAt.toDate().toLocaleString()
                      : (item.createdAt?.toDate ? item.createdAt.toDate().toLocaleString() : 'Recent');

                    return (
                      <tr key={item.id}>
                        <td style={{ maxWidth: 280 }}>
                          <strong style={{ color: 'var(--text)', display: 'block', fontSize: 13 }}>
                            {item.title}
                          </strong>
                          <span style={{ color: 'var(--text-2)', fontSize: 12, lineHeight: 1.3, display: 'block' }}>
                            {item.body}
                          </span>
                        </td>
                        <td>
                          <span className="badge badge-gray">{item.targetSummary || 'All Users'}</span>
                        </td>
                        <td>
                          <strong style={{ color: 'var(--green)' }}>~{item.recipientCount || 0}</strong>
                        </td>
                        <td>
                          {item.route ? (
                            <code style={{ fontSize: 11, color: 'var(--green)' }}>{item.route}</code>
                          ) : (
                            <span style={{ color: 'var(--text-2)', fontSize: 11 }}>None</span>
                          )}
                        </td>
                        <td style={{ fontSize: 11, color: 'var(--text-2)' }}>{sentAt}</td>
                        <td>
                          <span className="badge badge-green">Sent</span>
                        </td>
                        <td>
                          <button
                            className="btn btn-ghost btn-sm"
                            onClick={() => handleDeleteLog(item.id)}
                            title="Delete log entry"
                          >
                            <Trash2 size={13} color="var(--danger)" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )
        ) : (
          /* Scheduled Notifications Table */
          scheduledList.length === 0 ? (
            <div className="empty">
              <Calendar size={32} />
              <p>No notifications currently scheduled</p>
            </div>
          ) : (
            <div className="table-wrap" style={{ border: 'none' }}>
              <table>
                <thead>
                  <tr>
                    <th>Title & Content</th>
                    <th>Target</th>
                    <th>Estimated</th>
                    <th>Scheduled For</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {scheduledList.map((item) => {
                    const isPending = item.status === 'scheduled';
                    return (
                      <tr key={item.id}>
                        <td style={{ maxWidth: 280 }}>
                          <strong style={{ color: 'var(--text)', display: 'block', fontSize: 13 }}>
                            {item.title}
                          </strong>
                          <span style={{ color: 'var(--text-2)', fontSize: 12, lineHeight: 1.3, display: 'block' }}>
                            {item.body}
                          </span>
                        </td>
                        <td>
                          <span className="badge badge-gray">{item.targetSummary || 'All Users'}</span>
                        </td>
                        <td>
                          <strong style={{ color: 'var(--warning)' }}>~{item.recipientCount || 0}</strong>
                        </td>
                        <td style={{ fontSize: 12, color: 'var(--text)' }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <Clock size={13} color="var(--warning)" />
                            <span>{new Date(item.scheduledAt).toLocaleString()}</span>
                          </div>
                        </td>
                        <td>
                          <span
                            className={`badge ${
                              item.status === 'sent'
                                ? 'badge-green'
                                : item.status === 'cancelled'
                                ? 'badge-red'
                                : 'badge-orange'
                            }`}
                          >
                            {(item.status || 'scheduled').toUpperCase()}
                          </span>
                        </td>
                        <td>
                          {isPending && (
                            <button
                              className="btn btn-danger btn-sm"
                              onClick={() => handleCancelScheduled(item.id, item.title)}
                              disabled={cancellingId === item.id}
                            >
                              <XCircle size={13} />
                              <span>{cancellingId === item.id ? 'Cancelling...' : 'Cancel'}</span>
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )
        )}
      </div>
    </div>
  );
}
