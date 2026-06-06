import React, { useEffect, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  LayoutDashboard, 
  Users, 
  Map, 
  QrCode, 
  CheckSquare, 
  AlertTriangle, 
  Settings, 
  LogOut, 
  Sun, 
  Moon,
  Menu,
  X,
  Wallet
} from 'lucide-react';
import './AdminLayout.css';

export const AdminLayout: React.FC = () => {
  const { user, signOut } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Initialize theme from localStorage or system preference
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null;
    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    const initialTheme = savedTheme || systemTheme;
    setTheme(initialTheme);
    document.documentElement.setAttribute('data-theme', initialTheme);
  }, []);

  const toggleTheme = () => {
    const nextTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(nextTheme);
    document.documentElement.setAttribute('data-theme', nextTheme);
    localStorage.setItem('theme', nextTheme);
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/login');
  };

  const menuItems = [
    { path: '/', label: 'لوحة الإحصائيات', icon: LayoutDashboard },
    { path: '/users', label: 'الطلاب والسائقين', icon: Users },
    { path: '/routes', label: 'إدارة الخطوط', icon: Map },
    { path: '/licenses', label: 'حزم تراخيص الاشتراك', icon: QrCode },
    { path: '/payments', label: 'تأكيد المدفوعات اليدوية', icon: CheckSquare },
    { path: '/payouts', label: 'مستحقات ومحافظ السائقين', icon: Wallet },
    { path: '/emergency', label: 'طوارئ SOS والدعم', icon: AlertTriangle },
    { path: '/config', label: 'إعدادات المنصة', icon: Settings },
  ];

  // Map route path to page title in Arabic
  const getPageTitle = () => {
    const current = menuItems.find(item => item.path === location.pathname);
    return current ? current.label : 'إدارة سير';
  };

  return (
    <div className="admin-layout">
      {/* Sidebar Navigation */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          <div className="logo-box">
            <span className="logo-icon">
              <svg viewBox="0 0 1024 1024" style={{ width: '100%', height: '100%', borderRadius: '4px' }}>
                <rect width="1024" height="1024" fill="#1A1A1A"/>
                <g transform="translate(512,512) rotate(45)">
                  <path d="M -220,-310 C -220,-115 220,-115 220,0 C 220,115 110,225 0,225 C -60,225 -110,175 -110,115 C -110,85 -85,60 -55,60" fill="none" stroke="#1A1A1A" strokeWidth="160" strokeLinecap="round" />
                  <path d="M 220,310 C 220,115 -220,115 -220,0 C -220,-115 -110,-225 0,-225 C 60,-225 110,-175 110,-115 C 110,-85 85,-60 55,-60" fill="none" stroke="#1A1A1A" strokeWidth="160" strokeLinecap="round" />
                  <path d="M -220,-310 C -220,-115 220,-115 220,0 C 220,115 110,225 0,225 C -60,225 -110,175 -110,115 C -110,85 -85,60 -55,60" fill="none" stroke="var(--primary)" strokeWidth="100" strokeLinecap="round" />
                  <path d="M 220,310 C 220,115 -220,115 -220,0 C -220,-115 -110,-225 0,-225 C 60,-225 110,-175 110,-115 C 110,-85 85,-60 55,-60" fill="none" stroke="#FFFFFF" strokeWidth="100" strokeLinecap="round" />
                  <g transform="translate(-220,-310)">
                    <path d="M 0,65 C -40,42 -63,14 -63,-18 A 63,63 0 0 1 63,-18 C 63,14 40,42 0,65 Z" fill="var(--primary)" />
                    <circle cx="0" cy="-18" r="24" fill="#1A1A1A" />
                  </g>
                  <circle cx="220" cy="310" r="50" fill="#FFFFFF" />
                </g>
              </svg>
            </span>
            <h2>Sayr Admin</h2>
          </div>
          <button className="sidebar-close-btn" onClick={() => setSidebarOpen(false)}>
            <X size={20} />
          </button>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
                onClick={() => setSidebarOpen(false)}
              >
                <Icon size={20} className="nav-icon" />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="user-profile">
            <div className="avatar">{user?.email?.substring(0, 2).toUpperCase() || 'AD'}</div>
            <div className="info">
              <span className="name">مدير المنصة</span>
              <span className="email">{user?.email}</span>
            </div>
          </div>
          <button className="signout-btn" onClick={handleSignOut}>
            <LogOut size={18} />
            <span>تسجيل الخروج</span>
          </button>
        </div>
      </aside>

      {/* Main Layout Area */}
      <div className="main-content-wrapper">
        <header className="topbar">
          <div className="topbar-right">
            <button className="menu-toggle-btn" onClick={() => setSidebarOpen(true)}>
              <Menu size={24} />
            </button>
            <h1 className="page-title">{getPageTitle()}</h1>
          </div>

          <div className="topbar-left">
            {/* Theme Toggle Button */}
            <button className="theme-toggle-btn" onClick={toggleTheme} aria-label="Toggle theme">
              {theme === 'light' ? <Moon size={20} /> : <Sun size={20} />}
            </button>
          </div>
        </header>

        <main className="page-body">
          <Outlet />
        </main>
      </div>

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && <div className="sidebar-overlay" onClick={() => setSidebarOpen(false)}></div>}
    </div>
  );
};
