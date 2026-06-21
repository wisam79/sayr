import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { AlertOctagon, CheckCircle, Navigation, ExternalLink } from 'lucide-react';
import { useToast } from '../components/Toast';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';

interface EmergencyReport {
  id: string;
  message: string | null;
  latitude: number;
  longitude: number;
  status: 'active' | 'acknowledged' | 'resolved';
  created_at: string;
  profiles: {
    full_name: string;
    phone: string;
    role: string;
  };
  trips: {
    id: string;
    routes: {
      title: string;
    };
  };
}

export const EmergencyAlerts: React.FC = () => {
  const { showToast } = useToast();
  const [reports, setReports] = useState<EmergencyReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // ConfirmDialog State
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmMessage, setConfirmMessage] = useState('');

  useEffect(() => {
    fetchEmergencyReports();

    // Set up real-time listener for new SOS alerts
    const channel = supabase
      .channel('realtime_emergency_reports')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'emergency_reports' },
        (payload) => {
          console.log('New real-time SOS report received:', payload);
          // Reload to get joined details
          fetchEmergencyReports();
          // Optional: Trigger system audio notification
          try {
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-600.wav');
            audio.play();
          } catch (e) {
            console.warn('Audio play blocked or unavailable');
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  async function fetchEmergencyReports() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('emergency_reports')
        .select(`
          id,
          message,
          latitude,
          longitude,
          status,
          created_at,
          profiles:user_id (
            full_name,
            phone,
            role
          ),
          trips:trip_id (
            id,
            routes:route_id (
              title
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const formatted = (data as any[]).map(r => ({
        ...r,
        profiles: Array.isArray(r.profiles) ? r.profiles[0] : r.profiles,
        trips: Array.isArray(r.trips) ? r.trips[0] : r.trips
      }));

      setReports(formatted);
    } catch (err) {
      showToast('فشل في جلب بلاغات الطوارئ', 'error');
    } finally {
      setLoading(false);
    }
  }

  const triggerResolveAlert = (reportId: string) => {
    setConfirmMessage('هل أنت متأكد من حل هذه الاستغاثة وإغلاق بلاغ الطوارئ نهائياً؟');
    setConfirmAction(() => async () => {
      await handleUpdateStatus(reportId, 'resolved');
    });
    setConfirmOpen(true);
  };

  const handleUpdateStatus = async (reportId: string, nextStatus: 'acknowledged' | 'resolved') => {
    setActionLoadingId(reportId);
    try {
      const { error } = await supabase.rpc('admin_resolve_emergency', {
        p_id: reportId,
        p_status: nextStatus,
        p_notes: null
      });

      if (error) throw error;

      setReports(prev => prev.map(r => r.id === reportId ? { ...r, status: nextStatus } : r));
      showToast(
        nextStatus === 'acknowledged'
          ? 'تم استلام بلاغ الطوارئ وجاري المتابعة والحل'
          : 'تم إغلاق بلاغ الطوارئ وحل المشكلة بنجاح',
        'success'
      );
    } catch (err) {
      showToast('فشل في تحديث حالة بلاغ الطوارئ', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const getMapLink = (lat: number, lng: number) => {
    return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
  };

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {/* Alert Feed Container */}
      {loading ? (
        <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
      ) : reports.length === 0 ? (
        <EmptyState
          icon={CheckCircle}
          title="لا توجد بلاغات طوارئ حالياً"
          description="كل شيء يسير على ما يرام! لا توجد أي بلاغات طوارئ أو استغاثات SOS معلقة في النظام حالياً."
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {reports.map((report) => (
            <div 
              key={report.id} 
              className="card"
              style={{
                borderRight: `5px solid ${
                  report.status === 'active' ? 'var(--danger)' : 
                  report.status === 'acknowledged' ? 'var(--warning)' : '#10b981'
                }`,
                display: 'flex',
                flexWrap: 'wrap',
                justifyContent: 'space-between',
                alignItems: 'center',
                gap: '20px'
              }}
            >
              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start', flex: 1, minWidth: '300px' }}>
                <div style={{
                  backgroundColor: report.status === 'active' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                  color: report.status === 'active' ? 'var(--danger)' : 'var(--warning)',
                  padding: '12px',
                  borderRadius: 'var(--radius-sm)'
                }}>
                  <AlertOctagon size={24} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    استغاثة طوارئ نشطة من {report.profiles?.full_name || 'طالب مجهول'}
                    <span className={`badge ${
                      report.status === 'active' ? 'badge-danger' : 
                      report.status === 'acknowledged' ? 'badge-warning' : 'badge-success'
                    }`}>
                      {report.status === 'active' ? 'خطرة / نشطة' : 
                       report.status === 'acknowledged' ? 'قيد المتابعة' : 'تم حلها'}
                    </span>
                  </h3>
                  <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                    <strong>رقم الهاتف:</strong> {report.profiles?.phone || '—'} | 
                    <strong>الخط:</strong> {report.trips?.routes?.title || 'غير محدد'} | 
                    <strong>الوقت:</strong> {new Date(report.created_at).toLocaleString('ar-IQ')}
                  </p>
                  <p style={{ fontSize: '0.9rem', padding: '10px', backgroundColor: 'var(--bg-primary)', borderRadius: 'var(--radius-xs)', border: '1px solid var(--border-color)' }}>
                    <strong>رسالة الاستغاثة:</strong> {report.message || 'أرسل نداء طوارئ بدون كتابة نص (نقرة سريعة)'}
                  </p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                {/* Google Map location redirect */}
                <a 
                  href={getMapLink(report.latitude, report.longitude)}
                  target="_blank" 
                  rel="noopener noreferrer" 
                  className="btn btn-secondary"
                  style={{ height: '36px', fontSize: '0.8rem' }}
                >
                  <Navigation size={14} />
                  <span>تحديد الموقع على الخريطة</span>
                  <ExternalLink size={12} />
                </a>

                {report.status === 'active' && (
                  <button 
                    className="btn btn-primary"
                    style={{ height: '36px', fontSize: '0.8rem', backgroundColor: 'var(--warning)', borderColor: 'var(--warning)' }}
                    onClick={() => handleUpdateStatus(report.id, 'acknowledged')}
                    disabled={actionLoadingId === report.id}
                  >
                    قبول وتأكيد الاستلام
                  </button>
                )}

                {(report.status === 'active' || report.status === 'acknowledged') && (
                  <button 
                    className="btn btn-primary"
                    style={{ height: '36px', fontSize: '0.8rem' }}
                    onClick={() => triggerResolveAlert(report.id)}
                    disabled={actionLoadingId === report.id}
                  >
                    تأكيد حل المشكلة
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmOpen}
        title="تأكيد حل البلاغ"
        message={confirmMessage}
        variant="danger"
        confirmLabel="نعم، تم الحل"
        cancelLabel="إلغاء"
        onConfirm={async () => {
          if (confirmAction) {
            await confirmAction();
          }
          setConfirmOpen(false);
        }}
        onCancel={() => setConfirmOpen(false)}
      />
    </div>
  );
};
