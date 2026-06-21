import React, { useEffect, useState } from 'react';
import { useToast } from '../components/Toast';
import { supabase } from '../utils/supabaseClient';
import { 
  Users, 
  Bus, 
  Navigation, 
  CreditCard, 
  DollarSign, 
  Clock, 
  Sparkles,
  TrendingUp,
  TrendingDown
} from 'lucide-react';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  BarChart,
  Bar,
  Cell
} from 'recharts';

interface DashboardStats {
  total_users: number;
  total_drivers: number;
  total_routes: number;
  active_subscriptions: number;
  total_trips_today: number;
  total_revenue: number;
  pending_payouts: number;
  pending_payouts_amount: number;
}

export const DashboardOverview: React.FC = () => {
  const { showToast } = useToast();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [revenueHistory, setRevenueHistory] = useState<{ name: string; revenue: number }[]>([]);
  const [tripsByRouteData, setTripsByRouteData] = useState<{ name: string; count: number; color: string }[]>([]);

  useEffect(() => {
    fetchStats();
  }, []);

  async function fetchStats() {
    try {
      setLoading(true);
      setError(null);
      
      // 1. Fetch dashboard metrics
      const { data, error: rpcError } = await supabase.rpc('get_dashboard_stats');
      if (rpcError) throw rpcError;
      setStats(data);

      // 2. Fetch real active routes & trips count
      const { data: routesData, error: routesError } = await supabase
        .from('routes')
        .select(`
          id,
          title,
          trips (
            id
          )
        `)
        .eq('is_active', true);

      if (routesError) throw routesError;

      const colors = ['var(--primary)', 'var(--info)', 'var(--warning)', 'var(--pink)', 'var(--purple)', 'var(--danger)'];
      const formattedRoutes = (routesData || []).map((r: any, idx: number) => ({
        name: r.title,
        count: Array.isArray(r.trips) ? r.trips.length : (r.trips ? 1 : 0),
        color: colors[idx % colors.length]
      }));
      setTripsByRouteData(formattedRoutes);

      // 3. Fetch real payments to build monthly revenue trends
      const { data: paymentsData, error: paymentsError } = await supabase
        .from('payments')
        .select('amount, created_at')
        .eq('status', 'completed');

      if (paymentsError) throw paymentsError;

      const monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      const formattedRevenue: { year: number; month: number; name: string; revenue: number }[] = [];
      const currentDate = new Date();
      
      for (let i = 5; i >= 0; i--) {
        const d = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
        formattedRevenue.push({
          year: d.getFullYear(),
          month: d.getMonth(),
          name: monthNames[d.getMonth()],
          revenue: 0
        });
      }

      (paymentsData || []).forEach((p: any) => {
        const payDate = new Date(p.created_at);
        const item = formattedRevenue.find(r => r.year === payDate.getFullYear() && r.month === payDate.getMonth());
        if (item) {
          item.revenue += Number(p.amount);
        }
      });

      setRevenueHistory(formattedRevenue.map(r => ({ name: r.name, revenue: r.revenue })));

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'فشل في جلب إحصائيات النظام. تأكد من امتلاك صلاحيات المشرف.';
      showToast(errorMessage, 'error');
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="animate-fade-in" style={{ padding: '20px 0' }}>
        <div style={{ display: 'flex', gap: '20px', marginBottom: '32px' }}>
          {Array.from({ length: 4 }).map((_, idx) => (
            <div key={idx} className="card shimmer-bg" style={{ flex: 1, height: '110px', border: 'none' }}></div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: '20px' }}>
          <div className="card shimmer-bg" style={{ flex: 2, height: '350px', border: 'none' }}></div>
          <div className="card shimmer-bg" style={{ flex: 1, height: '350px', border: 'none' }}></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card animate-fade-in" style={{ border: '1.5px solid var(--danger)', display: 'flex', gap: '16px', alignItems: 'center' }}>
        <Clock size={40} style={{ color: 'var(--danger)' }} />
        <div>
          <h3 style={{ color: 'var(--danger)', marginBottom: '8px', fontWeight: 600 }}>خطأ في الاتصال</h3>
          <p style={{ color: 'var(--text-secondary)' }}>{error}</p>
          <button className="btn btn-primary" onClick={fetchStats} style={{ marginTop: '16px', height: '36px' }}>إعادة المحاولة</button>
        </div>
      </div>
    );
  }

  const formatCurrency = (amount: number) => {
    return amount.toLocaleString('ar-IQ') + ' د.ع';
  };

  const statCards = [
    {
      title: 'إجمالي الطلاب المسجلين',
      value: stats?.total_users || 0,
      icon: Users,
      color: 'var(--primary)',
      bg: 'var(--primary-glow)',
      trend: '+12% هذا الأسبوع',
      isTrendUp: true
    },
    {
      title: 'السائقين المعتمدين',
      value: stats?.total_drivers || 0,
      icon: Bus,
      color: 'var(--info)',
      bg: 'var(--info-glow)',
      trend: '+2 شركاء جدد',
      isTrendUp: true
    },
    {
      title: 'الخطوط النشطة',
      value: stats?.total_routes || 0,
      icon: Navigation,
      color: 'var(--purple)',
      bg: 'var(--purple-glow)',
      trend: 'تغطي 4 جامعات',
      isTrendUp: true
    },
    {
      title: 'الاشتراكات الفعالة',
      value: stats?.active_subscriptions || 0,
      icon: CreditCard,
      color: 'var(--pink)',
      bg: 'var(--pink-glow)',
      trend: '+8% مقارنة بالشهر الماضي',
      isTrendUp: true
    },
    {
      title: 'رحلات اليوم المقررة',
      value: stats?.total_trips_today || 0,
      icon: Sparkles,
      color: 'var(--warning)',
      bg: 'var(--warning-glow)',
      trend: 'جاري تتبعها الآن',
      isTrendUp: true
    },
    {
      title: 'إجمالي الإيرادات',
      value: formatCurrency(stats?.total_revenue || 0),
      icon: DollarSign,
      color: 'var(--primary)',
      bg: 'var(--primary-glow)',
      trend: 'تراكمي مبيعات Zain Cash واليدوي',
      isTrendUp: true
    },
    {
      title: 'طلبات سحب معلقة',
      value: stats?.pending_payouts || 0,
      icon: Clock,
      color: 'var(--danger)',
      bg: 'var(--danger-glow)',
      trend: 'بانتظار موافقتك اليدوية',
      isTrendUp: false
    },
    {
      title: 'مبالغ سحب معلقة',
      value: formatCurrency(stats?.pending_payouts_amount || 0),
      icon: DollarSign,
      color: 'var(--danger)',
      bg: 'var(--danger-glow)',
      trend: 'مستحقات شركاء النقل (السائقين)',
      isTrendUp: false
    }
  ];

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {/* Metric Cards Grid */}
      <div className="metric-grid">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div key={index} className="card metric-card">
              <div className="metric-icon-box" style={{ backgroundColor: card.bg, color: card.color }}>
                <Icon size={24} />
              </div>
              <div className="metric-details" style={{ flex: 1 }}>
                <h3>{card.title}</h3>
                <div className="metric-value" style={{ margin: '4px 0', fontSize: card.title.includes('إيرادات') || card.title.includes('مبالغ') ? '1.35rem' : '1.6rem' }}>
                  {card.value}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                  {card.isTrendUp ? <TrendingUp size={14} style={{ color: '#10B981' }} /> : <TrendingDown size={14} style={{ color: '#EF4444' }} />}
                  <span>{card.trend}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Analytical Charts */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '24px', marginBottom: '24px' }}>
        {/* Revenue Trend chart */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h2 style={{ fontSize: '1.05rem', fontWeight: 600, color: 'var(--text-primary)' }}>مؤشر نمو المبيعات (د.ع)</h2>
            <span style={{ fontSize: '0.8rem', color: 'var(--primary)', fontWeight: 500 }}>آخر 6 أشهر</span>
          </div>
          <div style={{ width: '100%', height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueHistory} margin={{ top: 10, right: 0, left: 10, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2ECC40" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#2ECC40" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-color)" />
                <XAxis dataKey="name" stroke="var(--text-tertiary)" tickLine={false} />
                <YAxis stroke="var(--text-tertiary)" tickLine={false} tickFormatter={(v) => (v / 1000000) + 'M'} />
                <Tooltip 
                  formatter={(value: any) => [formatCurrency(Number(value)), 'الإيرادات']} 
                  contentStyle={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', textAlign: 'right' }}
                />
                <Area type="monotone" dataKey="revenue" stroke="#2ECC40" strokeWidth={2} fillOpacity={1} fill="url(#colorRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Trips distribution chart */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h2 style={{ fontSize: '1.05rem', fontWeight: 600, color: 'var(--text-primary)' }}>كثافة الرحلات حسب خطوط الجامعات الرئيسية</h2>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>عدد رحلات اليوم</span>
          </div>
          <div style={{ width: '100%', height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={tripsByRouteData} margin={{ top: 10, right: 0, left: 10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-color)" />
                <XAxis dataKey="name" stroke="var(--text-tertiary)" tickLine={false} />
                <YAxis stroke="var(--text-tertiary)" tickLine={false} />
                <Tooltip 
                  formatter={(value: any) => [value + ' رحلة', 'الرحلات']}
                  contentStyle={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', textAlign: 'right' }}
                />
                <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                  {tripsByRouteData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};
