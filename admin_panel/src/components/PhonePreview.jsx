import React from 'react';
import { Bell, Sparkles } from 'lucide-react';

export default function PhonePreview({ title, body, imageUrl, route }) {
  const currentTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="phone-preview">
      {/* Phone status bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16, fontSize: 11, color: '#888', padding: '0 4px' }}>
        <span>{currentTime}</span>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <span>5G</span>
          <span>100%</span>
        </div>
      </div>

      <div className="phone-screen">
        <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-2)', marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.5 }}>
          Lock Screen Preview
        </div>

        {/* Realistic Android / iOS Notification card */}
        <div className="preview-notif">
          <div className="preview-notif-icon">
            <Sparkles size={18} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 2 }}>
              <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--green)', letterSpacing: 0.3 }}>DEENFLOW</span>
              <span style={{ fontSize: 10, color: 'var(--text-2)' }}>now</span>
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, color: '#fff', marginBottom: 3, wordBreak: 'break-word' }}>
              {title || 'Daily Islamic Reminder'}
            </div>
            <div style={{ fontSize: 12, color: '#b0c4bb', lineHeight: 1.4, wordBreak: 'break-word' }}>
              {body || 'Tap to complete your daily habits and earn deed rewards.'}
            </div>

            {imageUrl && (
              <div style={{ marginTop: 8, borderRadius: 8, overflow: 'hidden', maxHeight: 110 }}>
                <img
                  src={imageUrl}
                  alt="preview"
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => { e.currentTarget.style.display = 'none'; }}
                />
              </div>
            )}

            {route && (
              <div style={{ marginTop: 6, fontSize: 10, color: 'var(--text-2)', display: 'flex', alignItems: 'center', gap: 4 }}>
                <span style={{ width: 4, height: 4, borderRadius: '50%', background: 'var(--green)' }}></span>
                Deep link: <code style={{ color: 'var(--green)' }}>{route}</code>
              </div>
            )}
          </div>
        </div>

        <div style={{ marginTop: 14, textAlign: 'center', fontSize: 10, color: 'var(--text-2)' }}>
          Swipe up to unlock
        </div>
      </div>
    </div>
  );
}
