import React, { useState, useEffect, useMemo } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  collection,
  doc,
  setDoc,
  addDoc,
  getDocs,
  serverTimestamp,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import {
  Send,
  Calendar,
  Sparkles,
  Users,
  Smartphone,
  Globe,
  Clock,
  ExternalLink,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';
import { db, functions } from '../firebase';
import PhonePreview from '../components/PhonePreview';
import ConfirmSendModal from '../components/ConfirmSendModal';

const DEEP_LINK_OPTIONS = [
  { value: '', label: 'None (Default Home)' },
  { value: '/unlock', label: 'Unlock Apps (/unlock)' },
  { value: '/progress', label: 'Progress & Stats (/progress)' },
  { value: '/deeds', label: 'Islamic Deeds Hub (/deeds)' },
  { value: '/notifications', label: 'In-App Notification Inbox (/notifications)' },
];

export default function SendNotification() {
  const location = useLocation();
  const navigate = useNavigate();

  // Form states
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [route, setRoute] = useState('');
  const [targetType, setTargetType] = useState('all'); // all, platform, language, inactive, specific
  const [platformTarget, setPlatformTarget] = useState('android');
  const [languageTarget, setLanguageTarget] = useState('bn');
  const [specificDeviceId, setSpecificDeviceId] = useState('');
  const [isScheduled, setIsScheduled] = useState(false);
  const [scheduledDateTime, setScheduledDateTime] = useState('');

  // Fleet data & recipient counting
  const [allUsers, setAllUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);

  // Modal & submission state
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [toast, setToast] = useState(null);

  // If navigated with targetDeviceId from UserList
  useEffect(() => {
    if (location.state?.targetDeviceId) {
      setTargetType('specific');
      setSpecificDeviceId(location.state.targetDeviceId);
    }
  }, [location.state]);

  // Load registered users to estimate recipients accurately
  useEffect(() => {
    async function loadFleet() {
      try {
        const snap = await getDocs(collection(db, 'users'));
        const users = [];
        snap.forEach((d) => users.push({ id: d.id, ...d.data() }));
        setAllUsers(users);
      } catch (err) {
        console.warn('Could not pre-load users:', err.message);
      } finally {
        setLoadingUsers(false);
      }
    }
    loadFleet();
  }, []);

  // Compute recipient count based on criteria
  const { recipientCount, targetSummary } = useMemo(() => {
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;

    let matched = allUsers;
    let summary = 'All Registered Users';

    if (targetType === 'platform') {
      matched = allUsers.filter((u) => (u.platform || '').toLowerCase() === platformTarget.toLowerCase());
      summary = `Platform: ${platformTarget.toUpperCase()}`;
    } else if (targetType === 'language') {
      matched = allUsers.filter((u) => (u.language || '').toLowerCase().startsWith(languageTarget.toLowerCase()));
      summary = `Language: ${languageTarget === 'bn' ? 'Bengali (bn)' : 'English (en)'}`;
    } else if (targetType === 'inactive') {
      matched = allUsers.filter((u) => {
        const t = u.lastActiveAt?.toMillis ? u.lastActiveAt.toMillis() : (u.lastActiveAt ? new Date(u.lastActiveAt).getTime() : 0);
        return now - t > 7 * dayMs;
      });
      summary = 'Inactive Users (> 7 days)';
    } else if (targetType === 'specific') {
      const trimmed = specificDeviceId.trim();
      matched = allUsers.filter((u) => (u.deviceId || u.id) === trimmed);
      summary = `Specific Device: ${trimmed.slice(0, 8)}...`;
    }

    // Filter only those that have an FCM token & enabled
    const reachable = matched.filter((u) => u.fcmToken && u.notificationsEnabled !== false);

    return {
      recipientCount: reachable.length,
      targetSummary: summary,
    };
  }, [allUsers, targetType, platformTarget, languageTarget, specificDeviceId]);

  const handleOpenConfirm = (e) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      showToast('Please fill in both notification title and body.', 'error');
      return;
    }
    if (isScheduled && !scheduledDateTime) {
      showToast('Please select a scheduled delivery date and time.', 'error');
      return;
    }
    setShowConfirmModal(true);
  };

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4500);
  };

  const handleSendNotification = async () => {
    setIsSubmitting(true);
    try {
      // Allocate persistent notification doc ID in Firestore
      const notifDocRef = doc(collection(db, 'notifications'));
      const notificationId = notifDocRef.id;

      const payload = {
        notificationId,
        id: notificationId,
        title: title.trim(),
        body: body.trim(),
        imageUrl: imageUrl.trim() || null,
        route: route || null,
        targetType,
        targetPlatform: targetType === 'platform' ? platformTarget : null,
        targetLanguage: targetType === 'language' ? languageTarget : null,
        targetDeviceId: targetType === 'specific' ? specificDeviceId.trim() : null,
        recipientCount,
        targetSummary,
        createdAt: serverTimestamp(),
      };

      // 1. Save to permanent 'notifications' collection
      await setDoc(notifDocRef, {
        ...payload,
        status: isScheduled ? 'scheduled' : 'sent',
        sentAt: serverTimestamp(),
      });

      if (isScheduled) {
        // Save to notifications_broadcast for 100% free-tier instant client synchronization
        const scheduledTimestamp = new Date(scheduledDateTime).getTime();
        await addDoc(collection(db, 'notifications_broadcast'), {
          ...payload,
          status: 'scheduled',
          scheduledAt: scheduledDateTime,
          scheduledTimestampMs: scheduledTimestamp,
          isScheduled: true,
        });

        showToast('Notification successfully scheduled and broadcasted to devices!', 'success');
      } else {
        // Immediate dispatch
        // 2. Publish to notifications_broadcast for instant free-tier sync to all active apps
        await addDoc(collection(db, 'notifications_broadcast'), {
          ...payload,
          status: 'active',
          isScheduled: false,
          sentAt: serverTimestamp(),
        });

        // 3. Record in legacy notifications_log for backward compatibility
        await setDoc(doc(db, 'notifications_log', notificationId), {
          ...payload,
          status: 'sent',
          sentAt: serverTimestamp(),
        });

        showToast(`Successfully dispatched to ~${recipientCount} devices (100% Free)!`, 'success');
      }

      setShowConfirmModal(false);
      // Reset form
      setTitle('');
      setBody('');
      setImageUrl('');
      setRoute('');
      setIsScheduled(false);
      setScheduledDateTime('');
      setTimeout(() => navigate('/history'), 1200);
    } catch (err) {
      console.error('Dispatch error:', err);
      showToast(`Error sending notification: ${err.message}`, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Send Push Notification</h1>
          <p className="page-sub">
            Compose and dispatch Firebase Cloud Messaging alerts with offline local scheduling
          </p>
        </div>
      </div>

      {toast && (
        <div className="toast-container">
          <div className={`toast ${toast.type}`}>
            {toast.type === 'success' ? <CheckCircle size={16} color="var(--green)" /> : <AlertCircle size={16} color="var(--danger)" />}
            <span>{toast.message}</span>
          </div>
        </div>
      )}

      <div className="compose-grid">
        {/* Compose Form */}
        <div className="card">
          <form onSubmit={handleOpenConfirm} style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            {/* Target Audience */}
            <div>
              <label className="form-label" style={{ marginBottom: 8, display: 'block' }}>
                TARGET RECIPIENTS
              </label>
              <div className="filter-bar" style={{ marginBottom: 12 }}>
                <button
                  type="button"
                  className={`filter-chip ${targetType === 'all' ? 'active' : ''}`}
                  onClick={() => setTargetType('all')}
                >
                  <Users size={13} style={{ marginRight: 4 }} /> All Users
                </button>
                <button
                  type="button"
                  className={`filter-chip ${targetType === 'platform' ? 'active' : ''}`}
                  onClick={() => setTargetType('platform')}
                >
                  <Smartphone size={13} style={{ marginRight: 4 }} /> By Platform
                </button>
                <button
                  type="button"
                  className={`filter-chip ${targetType === 'language' ? 'active' : ''}`}
                  onClick={() => setTargetType('language')}
                >
                  <Globe size={13} style={{ marginRight: 4 }} /> By Language
                </button>
                <button
                  type="button"
                  className={`filter-chip ${targetType === 'inactive' ? 'active' : ''}`}
                  onClick={() => setTargetType('inactive')}
                >
                  <Clock size={13} style={{ marginRight: 4 }} /> Inactive (&gt;7d)
                </button>
                <button
                  type="button"
                  className={`filter-chip ${targetType === 'specific' ? 'active' : ''}`}
                  onClick={() => setTargetType('specific')}
                >
                  Specific Device
                </button>
              </div>

              {/* Conditional Target options */}
              {targetType === 'platform' && (
                <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
                  <select
                    className="select"
                    value={platformTarget}
                    onChange={(e) => setPlatformTarget(e.target.value)}
                  >
                    <option value="android">Android Devices Only</option>
                    <option value="ios">iOS Devices Only</option>
                  </select>
                </div>
              )}

              {targetType === 'language' && (
                <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
                  <select
                    className="select"
                    value={languageTarget}
                    onChange={(e) => setLanguageTarget(e.target.value)}
                  >
                    <option value="bn">Bengali (bn)</option>
                    <option value="en">English (en)</option>
                  </select>
                </div>
              )}

              {targetType === 'specific' && (
                <div style={{ marginTop: 8 }}>
                  <input
                    type="text"
                    className="input"
                    placeholder="Enter Device UUID (e.g. 550e8400-e29b-41d4-a716-446655440000)"
                    value={specificDeviceId}
                    onChange={(e) => setSpecificDeviceId(e.target.value)}
                    required
                  />
                </div>
              )}

              {/* Recipient estimate banner */}
              <div style={{
                background: 'var(--surface-2)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-sm)',
                padding: '8px 12px',
                marginTop: 10,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                fontSize: 12,
              }}>
                <span style={{ color: 'var(--text-2)' }}>Reachable FCM Tokens:</span>
                <span className="badge badge-green">
                  {loadingUsers ? 'Counting...' : `${recipientCount} devices`}
                </span>
              </div>
            </div>

            <div className="divider" style={{ margin: 0 }} />

            {/* Notification Title */}
            <div className="form-group">
              <label className="form-label" htmlFor="title">
                NOTIFICATION TITLE *
              </label>
              <input
                id="title"
                type="text"
                className="input"
                placeholder="e.g. Remember to pray Dhuhr"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                maxLength={100}
                required
              />
              <span style={{ fontSize: 10, color: 'var(--text-2)', textAlign: 'right' }}>
                {title.length}/100
              </span>
            </div>

            {/* Notification Body */}
            <div className="form-group">
              <label className="form-label" htmlFor="body">
                MESSAGE BODY *
              </label>
              <textarea
                id="body"
                className="textarea"
                placeholder="e.g. Take a pause from screen time and earn rewards for your prayer today."
                value={body}
                onChange={(e) => setBody(e.target.value)}
                maxLength={400}
                required
              />
              <span style={{ fontSize: 10, color: 'var(--text-2)', textAlign: 'right' }}>
                {body.length}/400
              </span>
            </div>

            {/* Optional Image URL */}
            <div className="form-group">
              <label className="form-label" htmlFor="imageUrl">
                BANNER IMAGE URL (OPTIONAL)
              </label>
              <input
                id="imageUrl"
                type="url"
                className="input"
                placeholder="https://example.com/banner.jpg"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
              />
            </div>

            {/* Deep Link Action */}
            <div className="form-group">
              <label className="form-label" htmlFor="route">
                ON TAP DEEP-LINK ACTION
              </label>
              <select
                id="route"
                className="select"
                value={route}
                onChange={(e) => setRoute(e.target.value)}
              >
                {DEEP_LINK_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
              <span style={{ fontSize: 11, color: 'var(--text-2)' }}>
                When user taps the notification, the app navigates immediately to this screen.
              </span>
            </div>

            <div className="divider" style={{ margin: 0 }} />

            {/* Delivery Mode (Send Now vs Schedule) */}
            <div>
              <label className="form-label" style={{ marginBottom: 8, display: 'block' }}>
                DELIVERY SCHEDULE
              </label>
              <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
                <button
                  type="button"
                  className={`filter-chip ${!isScheduled ? 'active' : ''}`}
                  onClick={() => setIsScheduled(false)}
                >
                  <Send size={13} style={{ marginRight: 4 }} /> Send Immediately
                </button>
                <button
                  type="button"
                  className={`filter-chip ${isScheduled ? 'active' : ''}`}
                  onClick={() => setIsScheduled(true)}
                >
                  <Calendar size={13} style={{ marginRight: 4 }} /> Schedule for Later
                </button>
              </div>

              {isScheduled && (
                <div className="form-group" style={{ marginTop: 10 }}>
                  <label className="form-label" htmlFor="schedDate">
                    DELIVERY DATE & TIME (LOCAL)
                  </label>
                  <input
                    id="schedDate"
                    type="datetime-local"
                    className="input"
                    value={scheduledDateTime}
                    onChange={(e) => setScheduledDateTime(e.target.value)}
                    min={new Date().toISOString().slice(0, 16)}
                    required={isScheduled}
                  />
                  <span style={{ fontSize: 11, color: 'var(--text-2)', marginTop: 4 }}>
                    ⚡ Dispatches a silent alarm to client devices so the alert triggers even if the phone is offline!
                  </span>
                </div>
              )}
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ justifyContent: 'center', marginTop: 10 }}
            >
              {isScheduled ? <Calendar size={16} /> : <Send size={16} />}
              <span>{isScheduled ? 'Review & Schedule' : 'Review & Send Now'}</span>
            </button>
          </form>
        </div>

        {/* Live Phone Preview */}
        <PhonePreview
          title={title}
          body={body}
          imageUrl={imageUrl}
          route={route}
        />
      </div>

      {/* Confirmation Modal */}
      <ConfirmSendModal
        isOpen={showConfirmModal}
        onClose={() => setShowConfirmModal(false)}
        onConfirm={handleSendNotification}
        isSubmitting={isSubmitting}
        title={title}
        body={body}
        targetSummary={targetSummary}
        recipientCount={recipientCount}
        isScheduled={isScheduled}
        scheduledDate={scheduledDateTime}
      />
    </div>
  );
}
