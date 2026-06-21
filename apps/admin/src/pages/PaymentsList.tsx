import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { CreditCard, Search, Eye } from 'lucide-react';
import { useToast } from '../components/Toast';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';

interface Payment {
  id: string;
  amount: number;
  currency: string;
  method: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  reference_id: string | null;
  paid_at: string | null;
  created_at: string;
  profiles: {
    full_name: string;
    phone: string;
  };
  subscriptions?: {
    id: string;
    routes: {
      title: string;
    };
  } | null;
}

export const PaymentsList: React.FC = () => {
  const { showToast } = useToast();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'completed'>('all');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // ConfirmDialog State
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmMessage, setConfirmMessage] = useState('');
  
  // Modal for viewing receipt metadata details
  const [viewingPayment, setViewingPayment] = useState<Payment | null>(null);

  useEffect(() => {
    fetchPayments();
  }, []);

  const fetchPayments = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('payments')
        .select(`
          id,
          amount,
          currency,
          method,
          status,
          reference_id,
          paid_at,
          created_at,
          profiles:user_id (
            full_name,
            phone
          ),
          subscriptions:subscription_id (
            id,
            routes:route_id (
              title
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const formatted = (data as any[]).map(p => ({
        ...p,
        profiles: Array.isArray(p.profiles) ? p.profiles[0] : p.profiles,
        subscriptions: Array.isArray(p.subscriptions) ? p.subscriptions[0] : p.subscriptions
      }));

      setPayments(formatted);
    } catch (err) {
      showToast('فشل في جلب طلبات الدفع والتحويلات المالية', 'error');
    } finally {
      setLoading(false);
    }
  };

  const triggerApprovePayment = (paymentId: string) => {
    setConfirmMessage('هل أنت متأكد من رغبتك في تفعيل هذا الترخيص وتأكيد استلام المبلغ يدوياً؟');
    setConfirmAction(() => async () => {
      await handleApprovePayment(paymentId);
    });
    setConfirmOpen(true);
  };

  const handleApprovePayment = async (paymentId: string) => {
    setActionLoadingId(paymentId);

    try {
      // Call the admin_approve_payment RPC migration we created
      const { error } = await supabase.rpc('admin_approve_payment', {
        p_payment_id: paymentId
      });

      if (error) throw error;

      // Update local state
      setPayments(prev => prev.map(p => {
        if (p.id === paymentId) {
          return { ...p, status: 'completed', paid_at: new Date().toISOString() };
        }
        return p;
      }));

      showToast('تم تأكيد الدفع وتفعيل ترخيص اشتراك الطالب بنجاح', 'success');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل في إتمام تأكيد الدفع';
      showToast(message, 'error');
    } finally {
      setActionLoadingId(null);
      setViewingPayment(null);
    }
  };

  const filteredPayments = payments.filter(p => {
    const matchesSearch = 
      (p.profiles?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (p.profiles?.phone || '').includes(searchTerm) ||
      (p.reference_id || '').includes(searchTerm);

    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {/* Search & Filters */}
      <div className="card" style={{ marginBottom: '24px', display: 'flex', flexWrap: 'wrap', gap: '16px', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ position: 'relative', minWidth: '280px' }}>
          <Search size={18} style={{ position: 'absolute', top: '50%', right: '12px', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
          <input 
            type="text" 
            className="form-input" 
            placeholder="البحث باسم الطالب أو رقم التحويل..." 
            style={{ paddingRight: '40px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>حالة الدفعة:</span>
          <select 
            className="form-input" 
            style={{ width: '150px', height: '38px', padding: '0 8px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
          >
            <option value="all">كل العمليات</option>
            <option value="pending">بانتظار التأكيد المعلق</option>
            <option value="completed">العمليات المؤكدة</option>
          </select>
        </div>
      </div>

      {/* Payments Table */}
      {loading ? (
        <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
      ) : filteredPayments.length === 0 ? (
        <EmptyState
          icon={CreditCard}
          title="لا توجد تحويلات مالية"
          description="لم يتم العثور على أي عمليات تحويل أو دفع مالي تطابق معايير البحث الحالية."
        />
      ) : (
        <div className="table-container">
          <table className="table-raw">
            <thead>
              <tr>
                <th>الطالب</th>
                <th>قيمة الفاتورة</th>
                <th>طريقة التحويل</th>
                <th>خط الاشتراك</th>
                <th>مرجع التحويل / الكود</th>
                <th>حالة العملية</th>
                <th>تاريخ الطلب</th>
                <th>الإجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filteredPayments.map(p => (
                <tr key={p.id}>
                  <td>
                    <div style={{ fontWeight: 600 }}>{p.profiles?.full_name || 'طالب مجهول'}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{p.profiles?.phone || '—'}</div>
                  </td>
                  <td><strong>{p.amount.toLocaleString('ar-IQ')} د.ع</strong></td>
                  <td>
                    <span className="badge" style={{ backgroundColor: 'var(--bg-tertiary)', color: 'var(--text-primary)' }}>
                      {p.method === 'zaincash' ? 'Zain Cash' : p.method === 'manual' ? 'AsiaCell يدوي' : 'دفع نقدي'}
                    </span>
                  </td>
                  <td>{p.subscriptions?.routes?.title || 'خط غير محدد'}</td>
                  <td>
                    <code style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                      {p.reference_id || 'لا يوجد'}
                    </code>
                  </td>
                  <td>
                    <span className={`badge ${
                      p.status === 'completed' ? 'badge-success' : 
                      p.status === 'pending' ? 'badge-warning' : 'badge-danger'
                    }`}>
                      {p.status === 'completed' ? 'مقبول / نشط' : 
                       p.status === 'pending' ? 'معلق للمراجعة' : 'فشلت'}
                    </span>
                  </td>
                  <td>{new Date(p.created_at).toLocaleDateString('ar-IQ')}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button 
                        className="btn btn-secondary" 
                        style={{ height: '32px', width: '32px', padding: 0 }}
                        onClick={() => setViewingPayment(p)}
                      >
                        <Eye size={14} />
                      </button>

                      {p.status === 'pending' && (
                        <button
                          className="btn btn-primary"
                          style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px' }}
                          onClick={() => triggerApprovePayment(p.id)}
                          disabled={actionLoadingId === p.id}
                        >
                          {actionLoadingId === p.id ? 'جاري التفعيل...' : 'تأكيد وقبول'}
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Details View Modal */}
      {viewingPayment && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '100%', maxWidth: '440px', padding: '32px' }}>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '20px' }}>تفاصيل طلب الدفع المالي</h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.9rem', marginBottom: '24px' }}>
              <div><strong>الطالب:</strong> {viewingPayment.profiles?.full_name}</div>
              <div><strong>الهاتف:</strong> {viewingPayment.profiles?.phone}</div>
              <div><strong>القيمة:</strong> {viewingPayment.amount.toLocaleString('ar-IQ')} د.ع</div>
              <div><strong>وسيلة الدفع:</strong> {viewingPayment.method === 'zaincash' ? 'Zain Cash' : 'AsiaCell / تحويل يدوي'}</div>
              <div><strong>الخط المختار:</strong> {viewingPayment.subscriptions?.routes?.title}</div>
              <div><strong>رقم التحويل (Reference ID):</strong> <code style={{ color: 'var(--primary)' }}>{viewingPayment.reference_id || 'لا يوجد'}</code></div>
              <div><strong>الحالة الحالية:</strong> {viewingPayment.status === 'completed' ? 'عملية مؤكدة بنجاح' : 'طلب معلق بانتظار المشرف'}</div>
              {viewingPayment.paid_at && (
                <div><strong>تاريخ التأكيد:</strong> {new Date(viewingPayment.paid_at).toLocaleString('ar-IQ')}</div>
              )}
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button className="btn btn-secondary" onClick={() => setViewingPayment(null)}>
                إغلاق
              </button>
              {viewingPayment.status === 'pending' && (
                <button 
                  className="btn btn-primary" 
                  onClick={() => triggerApprovePayment(viewingPayment.id)}
                  disabled={actionLoadingId === viewingPayment.id}
                >
                  {actionLoadingId === viewingPayment.id ? 'جاري التأكيد...' : 'قبول وتفعيل الاشتراك'}
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmOpen}
        title="تأكيد تحصيل الدفعة"
        message={confirmMessage}
        variant="warning"
        confirmLabel="نعم، تأكيد الاستلام"
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
