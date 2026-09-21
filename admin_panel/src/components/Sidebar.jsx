import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Users, Bell, History, LogOut, Mosque
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/users', icon: Users, label: 'Users' },
  { to: '/send', icon: Bell, label: 'Send Notification' },
  { to: '/history', icon: History, label: 'History' },
];

export default function Sidebar() {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <aside className="sidebar layout-sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-icon">
          <Mosque size={18} />
        </div>
        <div>
          <span className="sidebar-logo-text">DeenFlow</span>
          <span className="sidebar-logo-badge">ADMIN</span>
        </div>
      </div>

      {/* Nav */}
      <nav className="sidebar-nav">
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
          >
            <Icon size={16} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="sidebar-footer">
        <button className="nav-item" style={{ width: '100%', background: 'none', border: 'none' }} onClick={handleLogout}>
          <LogOut size={16} />
          Sign Out
        </button>
      </div>
    </aside>
  );
}
