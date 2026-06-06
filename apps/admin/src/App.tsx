import React from 'react';
import { ToastProvider } from './components/Toast';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { AdminLayout } from './layouts/AdminLayout';
import { Login } from './pages/Login';
import { DashboardOverview } from './pages/DashboardOverview';
import { UsersList } from './pages/UsersList';
import { RoutesOverview } from './pages/RoutesOverview';
import { LicenseBatches } from './pages/LicenseBatches';
import { PaymentsList } from './pages/PaymentsList';
import { PayoutsManager } from './pages/PayoutsManager';
import { EmergencyAlerts } from './pages/EmergencyAlerts';
import { AppConfig } from './pages/AppConfig';
import { ActiveTripsTracker } from './pages/ActiveTripsTracker';

// Route guard checking authentication and admin permissions
const PrivateRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  const { user, role, loading } = useAuth();

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        backgroundColor: 'var(--bg-primary)',
        color: 'var(--text-primary)',
        fontSize: '1.2rem',
        fontWeight: 'bold',
        direction: 'rtl'
      }}>
        جاري التحقق من صلاحيات الدخول...
      </div>
    );
  }

  // Redirect to login if user not authenticated or not admin
  if (!user || role !== 'admin') {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export const App: React.FC = () => {
  return (
    <ToastProvider>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<Login />} />

            {/* Secure Admin Dashboard Routes */}
            <Route path="/" element={
              <PrivateRoute>
                <AdminLayout />
              </PrivateRoute>
            }>
              <Route index element={<DashboardOverview />} />
              <Route path="users" element={<UsersList />} />
              <Route path="routes" element={<RoutesOverview />} />
              <Route path="trips" element={<ActiveTripsTracker />} />
              <Route path="licenses" element={<LicenseBatches />} />
              <Route path="payments" element={<PaymentsList />} />
              <Route path="payouts" element={<PayoutsManager />} />
              <Route path="emergency" element={<EmergencyAlerts />} />
              <Route path="config" element={<AppConfig />} />
            </Route>

            {/* Catch-all fallback redirect */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ToastProvider>
  );
};

export default App;
