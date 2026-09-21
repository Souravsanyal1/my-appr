export default function StatCard({ label, value, sub, icon: Icon, accentColor = 'var(--green)' }) {
  return (
    <div className="stat-card">
      <div className="stat-card-accent" style={{ background: `linear-gradient(90deg, ${accentColor}, transparent)` }} />
      {Icon && (
        <div className="stat-icon">
          <Icon size={18} />
        </div>
      )}
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value ?? '—'}</div>
      {sub && <div className="stat-sub">{sub}</div>}
    </div>
  );
}
