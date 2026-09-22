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
  Clock,
  ChevronDown,
  ChevronRight,
  CheckCircle2,
  Eye,
  Smartphone,
  Check,
} from 'lucide-react';
import { db, functions } from '../firebase';
import dataLayer from '../services/dataLayerService';

function SentNotificationRow({ item, onDelete }) {
  const [expanded, setExpanded] = useState(false);
  const [receiptsData, setReceiptsData] = useState(null);
  const [loadingReceipts, setLoadingReceipts] = useState(false);

  useEffect(() => {
    if (!expanded) return;
    setLoadingReceipts(true);
    const unsub = dataLayer.subscribeNotificationRecipients(item.id, (data) => {
      setReceiptsData(data);
      setLoadingReceipts(false);
    });
    return () => unsub();
  }, [expanded, item.id]);

  const sentAt = item.sentAt?.toDate
    ? item.sentAt.toDate().toLocaleString()
    : item.createdAt?.toDate
    ? item.createdAt.toDate().toLocaleString()
    : 'Recent';

  const delivered = receiptsData?.deliveredCount ?? 0;
  const opened = receiptsData?.openedCount ?? 0;
  const estimated = item.recipientCount || 0;
  const openRate = delivered > 0 ? ((opened / delivered) * 100).toFixed(1) : '0.0';

  return (
    <React.Fragment>
      <tr>
        <td style={{ maxWidth: 280 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
            <button
              className="btn btn-ghost btn-sm"
              style={{ padding: '2px 4px', height: 'auto', marginTop: 2 }}
              onClick={() => setExpanded(!expanded)}
              title={expanded ? 'Collapse recipients' : 'Expand recipients'}
            >
              {expanded ? <ChevronDown size={15} /> : <ChevronRight size={15} />}
            </button>
            <div>
              <strong style={{ color: 'var(--text)', display: 'block', fontSize: 13 }}>
                {item.title}
              </strong>
              <span style={{ color: 'var(--text-2)', fontSize: 12, lineHeight: 1.3, display: 'block' }}>
                {item.body}
              </span>
            </div>
          </div>
        </td>
        <td>
          <span className="badge badge-gray">{item.targetSummary || 'All Users'}</span>
        </td>
        <td>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <span style={{ fontSize: 13, fontWeight: 'bold', color: 'var(--green)' }}>
              ~{estimated} targeted
            </span>
            <span style={{ fontSize: 11, color: 'var(--text-2)' }}>
              {delivered} delivered • {opened} opened
            </span>
          </div>
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
            onClick={() => onDelete(item.id)}
            title="Delete log entry"
          >
            <Trash2 size={13} color="var(--danger)" />
          </button>
        </td>
      </tr>

      {/* Expanded Recipient Delivery & Open Breakdown */}
      {expanded && (
        <tr>
          <td colSpan={7} style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '16px 24px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              {/* Quick Metrics Cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: 10 }}>
                <div style={{ background: 'var(--card-bg, #121A16)', padding: '10px 14px', borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block' }}>Targeted Devices</span>
                  <strong style={{ fontSize: 16, color: 'var(--text)' }}>{estimated}</strong>
                </div>
                <div style={{ background: 'var(--card-bg, #121A16)', padding: '10px 14px', borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block' }}>Confirmed Delivered</span>
                  <strong style={{ fontSize: 16, color: '#38BDF8' }}>{delivered}</strong>
                </div>
                <div style={{ background: 'var(--card-bg, #121A16)', padding: '10px 14px', borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block' }}>Opened / Tapped</span>
                  <strong style={{ fontSize: 16, color: 'var(--green)' }}>{opened}</strong>
                </div>
                <div style={{ background: 'var(--card-bg, #121A16)', padding: '10px 14px', borderRadius: 8, border: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 11, color: 'var(--text-2)', display: 'block' }}>Open Rate</span>
                  <strong style={{ fontSize: 16, color: 'var(--gold, #D4AF37)' }}>{openRate}%</strong>
                </div>
              </div>

              {/* Recipient Devices Table */}
              <div>
                <span style={{ fontSize: 12, fontWeight: 'bold', color: 'var(--text)', marginBottom: 8, display: 'block' }}>
                  Delivery Receipts per Device ({receiptsData?.recipients?.length || 0})
                </span>

                {loadingReceipts ? (
                  <div style={{ padding: 16, textAlign: 'center', color: 'var(--text-2)', fontSize: 12 }}>
                    Loading receipt receipts...
                  </div>
                ) : !receiptsData?.recipients || receiptsData.recipients.length === 0 ? (
                  <div style={{ padding: 12, background: 'rgba(0,0,0,0.2)', borderRadius: 6, color: 'var(--text-2)', fontSize: 12 }}>
                    No client device receipts reported yet. Receipts stream automatically when active devices receive FCM or poll in-app broadcasts.
                  </div>
                ) : (
                  <div style={{ maxHeight: 200, overflowY: 'auto', border: '1px solid var(--border)', borderRadius: 6 }}>
                    <table style={{ width: '100%', fontSize: 11, borderCollapse: 'collapse' }}>
                      <thead>
                        <tr style={{ background: 'rgba(255,255,255,0.03)', borderBottom: '1px solid var(--border)' }}>
                          <th style={{ padding: '6px 12px', textAlign: 'left' }}>Device ID</th>
                          <th style={{ padding: '6px 12px', textAlign: 'left' }}>Delivered At</th>
                          <th style={{ padding: '6px 12px', textAlign: 'left' }}>Opened At</th>
                          <th style={{ padding: '6px 12px', textAlign: 'left' }}>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {receiptsData.recipients.map((rec) => {
                          const delTime = rec.deliveredAt?.toDate ? rec.deliveredAt.toDate().toLocaleTimeString() : 'Received';
                          const openTime = rec.openedAt?.toDate ? rec.openedAt.toDate().toLocaleTimeString() : '—';
                          const isOpened = Boolean(rec.openedAt);

                          return (
                            <tr key={rec.deviceId} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }}>
                              <td style={{ padding: '6px 12px', fontFamily: 'monospace' }}>
                                <Smartphone size={11} style={{ display: 'inline', marginRight: 4, verticalAlign: -1 }} />
                                {rec.deviceId}
                              </td>
                              <td style={{ padding: '6px 12px', color: 'var(--text-2)' }}>{delTime}</td>
                              <td style={{ padding: '6px 12px', color: isOpened ? 'var(--green)' : 'var(--text-2)' }}>{openTime}</td>
                              <td style={{ padding: '6px 12px' }}>
                                {isOpened ? (
                                  <span className="badge badge-green" style={{ fontSize: 10, padding: '1px 6px' }}>
                                    <Eye size={9} style={{ marginRight: 3 }} /> Opened
                                  </span>
                                ) : (
                                  <span className="badge badge-blue" style={{ fontSize: 10, padding: '1px 6px' }}>
                                    <Check size={9} style={{ marginRight: 3 }} /> Delivered
                                  </span>
                                )}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          </td>
        </tr>
      )}
    </React.Fragment>
  );
}

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
          const ta = a.sentAt?.toMillis ? a.sentAt.toMillis() : a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
          const tb = b.sentAt?.toMillis ? b.sentAt.toMillis() : b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
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
      await deleteDoc(doc(db, 'notifications', id)).catch(() => {});
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
            Track past broadcast metrics, recipient delivery receipts, and manage scheduled offline local notifications
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
                    <th>Recipients & Status</th>
                    <th>Deep Link</th>
                    <th>Dispatched At</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {sentList.map((item) => (
                    <SentNotificationRow key={item.id} item={item} onDelete={handleDeleteLog} />
                  ))}
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
