import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { Search, Check, X, DollarSign, Clock, CheckCircle, AlertOctagon, Wallet } from 'lucide-react';
import { useToast } from '../components/Toast';
import { EmptyState } from '../components/EmptyState';
import './PayoutsManager.css';

interface Profile {
  full_name: string;
  phone: string;
}

interface Driver {
  id: string;
  vehicle_plate: string;
  profile: Profile | null;
}

interface PayoutRequest {
  id: string;
  amount: number;
  status: 'pending' | 'completed' | 'rejected';
  reference_note: string | null;
  rejection_reason: string | null;
  processed_at: string | null;
  created_at: string;
  driver: Driver | null;
}

export const PayoutsManager: React.FC = () => {
  const { showToast } = useToast();
  const [payouts, setPayouts] = useState<PayoutRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'completed' | 'rejected'>('all');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // Modal State
  const [activeRequest, setActiveRequest] = useState<PayoutRequest | null>(null);
  const [actionType, setActionType] = useState<'approve' | 'reject' | null>(null);
  const [note, setNote] = useState('');

  useEffect(() => {
    fetchPayouts();
  }, []);

  const fetchPayouts = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('driver_payouts')
        .select(`
          id,
          amount,
          status,
          reference_note,
          rejection_reason,
          processed_at,
          created_at,
          drivers:driver_id (
            id,
            vehicle_plate,
            profiles:user_id (
              full_name,
              phone
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const formatted: PayoutRequest[] = (data as any[]).map(p => {
        let driverData = p.drivers;
        if (Array.isArray(driverData)) {
          driverData = driverData[0];
        }
        let profileData = driverData?.profiles;
        if (Array.isArray(profileData)) {
          profileData = profileData[0];
        }
        return {
          id: p.id,
          amount: Number(p.amount),
          status: p.status,
          reference_note: p.reference_note,
          rejection_reason: p.rejection_reason,
          processed_at: p.processed_at,
          created_at: p.created_at,
          driver: driverData ? {
            id: driverData.id,
            vehicle_plate: driverData.vehicle_plate,
            profile: profileData ? {
              full_name: profileData.full_name,
              phone: profileData.phone
            } : null
          } : null
        };
      });

      setPayouts(formatted);
    } catch (err) {
      showToast('فشل في جلب طلبات المستحقات المالية', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleActionSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeRequest || !actionType) return;

    setActionLoadingId(activeRequest.id);
    const targetStatus = actionType === 'approve' ? 'completed' : 'rejected';

    try {
      // Call Supabase RPC to update payout status
      const { error } = await supabase.rpc('update_payout_status', {
        p_payout_id: activeRequest.id,
        p_new_status: targetStatus,
        p_note: note.trim() || null
      });

      if (error) throw error;

      // Sync the specific column in database for rejection reasons
      if (targetStatus === 'rejected' && note.trim()) {
        await supabase
          .from('driver_payouts')
          .update({ rejection_reason: note.trim() })
          .eq('id', activeRequest.id);
      }

      // Update local state
      setPayouts(prev => prev.map(p => {
        if (p.id === activeRequest.id) {
          return {
            ...p,
            status: targetStatus,
            reference_note: targetStatus === 'completed' ? (note.trim() || null) : p.reference_note,
            rejection_reason: targetStatus === 'rejected' ? (note.trim() || null) : p.rejection_reason,
            processed_at: new Date().toISOString()
          };
        }
        return p;
      }));

      showToast(
        targetStatus === 'completed' 
          ? 'تم اعتماد المستحقات وصرفها للسائق بنجاح' 
          : 'تم رفض طلب مستحقات السائق بنجاح',
        'success'
      );
      // Close modal
      closeModal();
    } catch (err: any) {
      showToast(err.message || 'حدث خطأ أثناء معالجة الطلب', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const openModal = (request: PayoutRequest, type: 'approve' | 'reject') => {
    setActiveRequest(request);
    setActionType(type);
    setNote('');
  };

  const closeModal = () => {
    setActiveRequest(null);
    setActionType(null);
    setNote('');
  };

  // Financial aggregates
  const totalPending = payouts
    .filter(p => p.status === 'pending')
    .reduce((acc, p) => acc + p.amount, 0);

  const totalPaid = payouts
    .filter(p => p.status === 'completed')
    .reduce((acc, p) => acc + p.amount, 0);

  const totalRejected = payouts
    .filter(p => p.status === 'rejected')
    .reduce((acc, p) => acc + p.amount, 0);

  // Filters
  const filteredPayouts = payouts.filter(p => {
    const matchesSearch = 
      (p.driver?.profile?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (p.driver?.profile?.phone || '').includes(searchTerm) ||
      (p.driver?.vehicle_plate || '').toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const formatCurrency = (val: number) => {
    return val.toLocaleString('ar-IQ') + ' د.ع';
  };

  const getStatusBadge = (status: PayoutRequest['status']) => {
    switch (status) {
      case 'pending':
        return <span className="payout-status status-pending"><Clock size={12} /> قيد الانتظار</span>;
      case 'completed':
        return <span className="payout-status status-completed"><CheckCircle size={12} /> مكتمل</span>;
      case 'rejected':
        return <span className="payout-status status-rejected"><AlertOctagon size={12} /> مرفوض</span>;
    }
  };

  return (
    <div className="payouts-container animate-fade-in">
      <div className="payouts-header">
        <h1>إدارة مستحقات السائقين</h1>
      </div>

      {/* Aggregate Finance Cards */}
      <div className="stats-grid">
        <div className="card stats-card">
          <div className="stats-icon-box" style={{ backgroundColor: 'rgba(245, 158, 11, 0.12)', color: '#f59e0b' }}>
            <DollarSign size={24} />
          </div>
          <div className="stats-details">
            <h3>المستحقات المعلقة</h3>
            <div className="stats-value">{formatCurrency(totalPending)}</div>
          </div>
        </div>

        <div className="card stats-card">
          <div className="stats-icon-box" style={{ backgroundColor: 'rgba(16, 185, 129, 0.12)', color: '#10b981' }}>
            <Check size={24} />
          </div>
          <div className="stats-details">
            <h3>إجمالي المبالغ المدفوعة</h3>
            <div className="stats-value">{formatCurrency(totalPaid)}</div>
          </div>
        </div>

        <div className="card stats-card">
          <div className="stats-icon-box" style={{ backgroundColor: 'rgba(239, 68, 68, 0.12)', color: '#ef4444' }}>
            <X size={24} />
          </div>
          <div className="stats-details">
            <h3>الطلبات المرفوضة</h3>
            <div className="stats-value">{formatCurrency(totalRejected)}</div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="payouts-filters">
        <div className="search-box">
          <Search size={18} />
          <input
            type="text"
            placeholder="البحث باسم السائق، رقم الهاتف، أو رقم اللوحة..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div className="filter-tabs">
          <button 
            className={`filter-tab ${statusFilter === 'all' ? 'active' : ''}`}
            onClick={() => setStatusFilter('all')}
          >
            الكل
          </button>
          <button 
            className={`filter-tab ${statusFilter === 'pending' ? 'active' : ''}`}
            onClick={() => setStatusFilter('pending')}
          >
            قيد الانتظار
          </button>
          <button 
            className={`filter-tab ${statusFilter === 'completed' ? 'active' : ''}`}
            onClick={() => setStatusFilter('completed')}
          >
            مكتملة
          </button>
          <button 
            className={`filter-tab ${statusFilter === 'rejected' ? 'active' : ''}`}
            onClick={() => setStatusFilter('rejected')}
          >
            مرفوضة
          </button>
        </div>
      </div>

      {/* Payout Grid/Table */}
      {loading ? (
        <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
      ) : filteredPayouts.length === 0 ? (
        <EmptyState
          icon={Wallet}
          title="لا توجد طلبات مستحقات حالياً"
          description="لم يتم العثور على أي طلبات سحب أو مستحقات مالية تطابق خيارات التصفية الحالية."
        />
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <table className="admin-table">
            <thead>
              <tr>
                <th>السائق</th>
                <th>رقم الهاتف</th>
                <th>لوحة السيارة</th>
                <th>المبلغ المطلوب</th>
                <th>تاريخ الطلب</th>
                <th>الحالة</th>
                <th>ملاحظات الإدارة</th>
                <th style={{ textAlign: 'left' }}>الإجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filteredPayouts.map((p) => (
                <tr key={p.id}>
                  <td style={{ fontWeight: 600, color: 'var(--text-primary)' }}>
                    {p.driver?.profile?.full_name || 'سائق غير معرف'}
                  </td>
                  <td>{p.driver?.profile?.phone || '-'}</td>
                  <td>{p.driver?.vehicle_plate || '-'}</td>
                  <td style={{ fontWeight: 700, color: 'var(--primary)' }}>
                    {formatCurrency(p.amount)}
                  </td>
                  <td>{new Date(p.created_at).toLocaleDateString('ar-IQ')}</td>
                  <td>{getStatusBadge(p.status)}</td>
                  <td style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {p.status === 'completed' && p.reference_note}
                    {p.status === 'rejected' && p.rejection_reason}
                    {p.status === 'pending' && '-'}
                  </td>
                  <td style={{ textAlign: 'left' }}>
                    {p.status === 'pending' && (
                      <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                        <button
                          className="btn btn-primary"
                          onClick={() => openModal(p, 'approve')}
                          disabled={actionLoadingId === p.id}
                          style={{ height: '32px', padding: '0 12px', fontSize: '0.8rem' }}
                        >
                          موافقة
                        </button>
                        <button
                          className="btn btn-secondary"
                          onClick={() => openModal(p, 'reject')}
                          disabled={actionLoadingId === p.id}
                          style={{ height: '32px', padding: '0 12px', fontSize: '0.8rem', color: '#ef4444', borderColor: '#ef4444' }}
                        >
                          رفض
                        </button>
                      </div>
                    )}
                    {p.status !== 'pending' && (
                      <span style={{ fontSize: '0.8rem', color: 'var(--text-tertiary)' }}>تمت المعالجة</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Action Dialog Modal */}
      {activeRequest && actionType && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>
                {actionType === 'approve' ? 'تأكيد دفع المستحقات اليدوي' : 'رفض طلب الدفع'}
              </h2>
              <button className="close-btn" onClick={closeModal}><X size={18} /></button>
            </div>

            <form onSubmit={handleActionSubmit}>
              <div className="modal-body">
                <div className="payout-detail-row">
                  <span className="payout-detail-label">اسم السائق:</span>
                  <span className="payout-detail-value">{activeRequest.driver?.profile?.full_name}</span>
                </div>
                <div className="payout-detail-row">
                  <span className="payout-detail-label">المبلغ:</span>
                  <span className="payout-detail-value" style={{ color: 'var(--primary)', fontWeight: 700 }}>
                    {formatCurrency(activeRequest.amount)}
                  </span>
                </div>

                <div className="form-group">
                  <label htmlFor="payout-note">
                    {actionType === 'approve' 
                      ? 'رقم مرجع التحويل أو الحوالة (Zain Cash ID / وصولات الدفع اليدوي):'
                      : 'سبب الرفض بالتفصيل (سيظهر للسائق في التطبيق):'}
                  </label>
                  <textarea
                    id="payout-note"
                    required
                    placeholder={actionType === 'approve' ? 'أدخل رقم العملية أو الحوالة...' : 'اكتب سبب رفض المعاملة هنا...'}
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={closeModal}
                  disabled={actionLoadingId !== null}
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className={`btn ${actionType === 'approve' ? 'btn-primary' : 'btn-reject'}`}
                  disabled={actionLoadingId !== null || !note.trim()}
                  style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
                >
                  {actionLoadingId !== null ? 'جاري المعالجة...' : actionType === 'approve' ? 'تأكيد وإتمام الدفع' : 'تأكيد الرفض'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
