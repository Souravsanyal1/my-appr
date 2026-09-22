import { useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const titles = {
  '/': 'Dashboard',
  '/users': 'Users',
  '/send': 'Send Notification',
  '/history': 'Notification History',
};

export default function Header() {
  const { pathname } = useLocation();
  const { user } = useAuth();
  const title = titles[pathname] ?? 'Admin';

  return (
    <header className="header layout-header">
      <span className="header-title">{title}</span>
      <div className="header-actions">
        <span className="admin-badge">Admin</span>
        <span style={{ fontSize: 13, color: 'var(--text-2)' }}>
          {user?.email}
        </span>
      </div>
    </header>
  );
}
