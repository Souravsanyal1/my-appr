import React from 'react';
import { AlertTriangle, Send, Calendar, Users, X } from 'lucide-react';

export default function ConfirmSendModal({
  isOpen,
  onClose,
  onConfirm,
  isSubmitting,
  title,
  body,
  targetSummary,
  recipientCount,
  isScheduled,
  scheduledDate,
}) {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: isScheduled ? 'rgba(245,166,35,0.15)' : 'var(--green-muted)',
              color: isScheduled ? 'var(--warning)' : 'var(--green)',
              display: 'grid', placeItems: 'center'
            }}>
              {isScheduled ? <Calendar size={18} /> : <Send size={18} />}
            </div>
            <h3 className="modal-title" style={{ margin: 0 }}>
              {isScheduled ? 'Confirm Scheduled Notification' : 'Confirm Send Notification'}
            </h3>
          </div>
          <button className="btn btn-ghost btn-icon" onClick={onClose} style={{ padding: 4 }}>
            <X size={18} />
          </button>
        </div>

        <div style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 20 }}>
          {isScheduled
            ? 'This notification will be scheduled and queued for offline delivery to devices.'
            : 'You are about to broadcast this push notification immediately.'}
        </div>

        <div style={{
          background: 'var(--surface-2)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-sm)',
          padding: 14,
          marginBottom: 20,
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
          fontSize: 12.5,
        }}>
          <div>
            <span style={{ color: 'var(--text-2)', display: 'block', fontSize: 11, marginBottom: 2 }}>MESSAGE TITLE</span>
            <strong style={{ color: 'var(--text)' }}>{title || '(No title)'}</strong>
          </div>

          <div>
            <span style={{ color: 'var(--text-2)', display: 'block', fontSize: 11, marginBottom: 2 }}>MESSAGE BODY</span>
            <span style={{ color: 'var(--text)', whiteSpace: 'pre-wrap' }}>{body || '(No body)'}</span>
          </div>

          <div className="divider" style={{ margin: '6px 0' }} />

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-2)', display: 'flex', alignItems: 'center', gap: 6 }}>
              <Users size={14} /> Target Audience
            </span>
            <span className="badge badge-green">{targetSummary}</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-2)' }}>Estimated Recipients</span>
            <strong style={{ color: 'var(--green)', fontSize: 14 }}>
              {recipientCount !== null ? recipientCount : 'Estimating...'}
            </strong>
          </div>

          {isScheduled && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: 'var(--text-2)' }}>Scheduled Delivery</span>
              <strong style={{ color: 'var(--warning)', fontSize: 13 }}>
                {scheduledDate ? new Date(scheduledDate).toLocaleString() : 'Immediate'}
              </strong>
            </div>
          )}
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button className="btn btn-ghost" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </button>
          <button
            className="btn btn-primary"
            onClick={onConfirm}
            disabled={isSubmitting || recipientCount === 0}
            style={{ minWidth: 120 }}
          >
            {isSubmitting ? (
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                Sending...
              </span>
            ) : isScheduled ? 'Schedule Now' : 'Send Multicast'}
          </button>
        </div>
      </div>
    </div>
  );
}
