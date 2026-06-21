import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { Plus, Ticket, Download, ArrowLeft, Key, ShieldCheck } from 'lucide-react';
import { useToast } from '../components/Toast';
import { EmptyState } from '../components/EmptyState';

interface Route {
  id: string;
  title: string;
}

interface Batch {
  id: string;
  batch_name: string;
  quantity: number;
  price: number;
  valid_days: number;
  created_at: string;
  routes: {
    title: string;
  };
}

interface License {
  id: string;
  code: string;
  status: 'active' | 'used' | 'expired' | 'revoked';
  used_by_profile?: {
    full_name: string;
  } | null;
  used_at: string | null;
}

export const LicenseBatches: React.FC = () => {
  const { showToast } = useToast();
  const [batches, setBatches] = useState<Batch[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  
  // Selected Batch for viewing codes
  const [selectedBatch, setSelectedBatch] = useState<Batch | null>(null);
  const [licenses, setLicenses] = useState<License[]>([]);
  const [licensesLoading, setLicensesLoading] = useState(false);

  // Form State
  const [routeId, setRouteId] = useState('');
  const [batchName, setBatchName] = useState('');
  const [quantity, setQuantity] = useState('');
  const [price, setPrice] = useState('');
  const [validDays, setValidDays] = useState('30');

  useEffect(() => {
    fetchBatches();
    fetchRoutes();
  }, []);

  async function fetchBatches() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('license_batches')
        .select(`
          id,
          batch_name,
          quantity,
          price,
          valid_days,
          created_at,
          routes:route_id (
            title
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const formattedData = (data as any[]).map(batch => ({
        ...batch,
        routes: Array.isArray(batch.routes) ? batch.routes[0] : batch.routes
      }));

      setBatches(formattedData);
    } catch (err) {
      showToast('فشل في تحميل حزم التراخيص', 'error');
    } finally {
      setLoading(false);
    }
  }

  async function fetchRoutes() {
    try {
      const { data, error } = await supabase
        .from('routes')
        .select('id, title')
        .eq('is_active', true);
      
      if (error) throw error;
      setRoutes(data || []);
    } catch (err) {
      showToast('فشل في جلب خطوط النقل النشطة', 'error');
    }
  }

  const handleCreateBatch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!routeId || !batchName || !quantity || !price || !validDays) {
      showToast('الرجاء إدخال جميع الحقول المطلوبة', 'warning');
      return;
    }

    setActionLoading(true);

    try {
      // Call Supabase RPC create_license_batch
      const { error } = await supabase.rpc('create_license_batch', {
        p_route_id: routeId,
        p_batch_name: batchName,
        p_quantity: parseInt(quantity),
        p_price: parseFloat(price),
        p_valid_days: parseInt(validDays)
      });

      if (error) throw error;

      showToast('تم توليد رموز الاشتراك وتخزينها بنجاح', 'success');
      setShowModal(false);
      // Reset Form
      setRouteId('');
      setBatchName('');
      setQuantity('');
      setPrice('');
      setValidDays('30');
      
      // Reload batches
      fetchBatches();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل في توليد رموز الاشتراك';
      showToast(message, 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const viewBatchLicenses = async (batch: Batch) => {
    setSelectedBatch(batch);
    setLicensesLoading(true);

    try {
      // Fetch licenses for selected batch
      const { data, error } = await supabase
        .from('licenses')
        .select(`
          id,
          code,
          status,
          used_at,
          used_by_profile:used_by (
            full_name
          )
        `)
        .eq('batch_id', batch.id);

      if (error) throw error;
      
      const formatted = (data as any[]).map(license => ({
        ...license,
        used_by_profile: Array.isArray(license.used_by_profile) ? license.used_by_profile[0] : license.used_by_profile
      }));

      setLicenses(formatted);
    } catch (err) {
      showToast('فشل في جلب رموز الاشتراك لهذه الحزمة', 'error');
    } finally {
      setLicensesLoading(false);
    }
  };

  const exportToCSV = () => {
    if (!selectedBatch || licenses.length === 0) return;
    
    try {
      // Create CSV content
      const headers = ['رمز الاشتراك (Code)', 'الحالة (Status)', 'المستخدم (User)', 'تاريخ التفعيل (Activated At)'];
      const rows = licenses.map(l => [
        l.code,
        l.status === 'active' ? 'نشط' : l.status === 'used' ? 'مستخدم' : l.status === 'expired' ? 'منتهي' : 'ملغي',
        l.used_by_profile?.full_name || 'غير مستخدم',
        l.used_at ? new Date(l.used_at).toLocaleDateString('ar-IQ') : '—'
      ]);
      
      const csvContent = "data:text/csv;charset=utf-8,\uFEFF" 
        + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
        
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement("a");
      link.setAttribute("href", encodedUri);
      link.setAttribute("download", `sayr_licenses_${selectedBatch.batch_name.replace(/\s+/g, '_')}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      showToast('تم تصدير الرموز بنجاح كملف CSV', 'success');
    } catch (err) {
      showToast('فشل في تصدير الرموز', 'error');
    }
  };

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {!selectedBatch ? (
        <>
          {/* Header Action */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '24px' }}>
            <button className="btn btn-primary" onClick={() => setShowModal(true)}>
              <Plus size={18} />
              <span>توليد رموز اشتراك جديدة</span>
            </button>
          </div>

          {/* Batches Table */}
          {loading ? (
            <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
          ) : batches.length === 0 ? (
            <EmptyState
              icon={Ticket}
              title="لا توجد حزم تراخيص حالياً"
              description="لم يتم العثور على أي حزمة تراخيص تم توليدها. يمكنك البدء بتوليد رموز اشتراك جديدة."
              actionLabel="توليد رموز اشتراك جديدة"
              onAction={() => setShowModal(true)}
            />
          ) : (
            <div className="table-container">
              <table className="table-raw">
                <thead>
                  <tr>
                    <th>اسم الحزمة</th>
                    <th>خط الحافلة المرتبط</th>
                    <th>الكمية المولدة</th>
                    <th>سعر التذكرة / الترخيص</th>
                    <th>فترة الصلاحية</th>
                    <th>تاريخ الإنشاء</th>
                    <th>الإجراءات</th>
                  </tr>
                </thead>
                <tbody>
                  {batches.map((batch) => (
                    <tr key={batch.id}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 600 }}>
                          <Ticket size={18} style={{ color: 'var(--primary)' }} />
                          <span>{batch.batch_name}</span>
                        </div>
                      </td>
                      <td>{batch.routes?.title || 'خط ملغي'}</td>
                      <td><strong>{batch.quantity}</strong> رمز</td>
                      <td>{batch.price.toLocaleString('ar-IQ')} د.ع</td>
                      <td>{batch.valid_days} يوم</td>
                      <td>{new Date(batch.created_at).toLocaleDateString('ar-IQ')}</td>
                      <td>
                        <button 
                          className="btn btn-secondary"
                          style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px' }}
                          onClick={() => viewBatchLicenses(batch)}
                        >
                          <Key size={14} style={{ marginLeft: '4px' }} /> عرض الرموز
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      ) : (
        /* View Batch Codes view */
        <div className="animate-fade-in">
          {/* Back button */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <button className="btn btn-secondary" onClick={() => setSelectedBatch(null)} style={{ height: '36px' }}>
              <ArrowLeft size={16} />
              <span>العودة للحزم</span>
            </button>

            <button className="btn btn-primary" onClick={exportToCSV} disabled={licenses.length === 0} style={{ height: '36px' }}>
              <Download size={16} />
              <span>تصدير الرموز كملف Excel/CSV</span>
            </button>
          </div>

          <div className="card" style={{ marginBottom: '24px' }}>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '8px' }}>تفاصيل الحزمة: {selectedBatch.batch_name}</h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
              الخط: <strong>{selectedBatch.routes?.title}</strong> | 
              العدد: <strong>{selectedBatch.quantity}</strong> | 
              الصلاحية: <strong>{selectedBatch.valid_days} يوم</strong>
            </p>
          </div>

          {licensesLoading ? (
            <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
          ) : (
            <div className="table-container">
              <table className="table-raw">
                <thead>
                  <tr>
                    <th>رمز الترخيص (Code)</th>
                    <th>حالة الرمز</th>
                    <th>الطالب المفعّل</th>
                    <th>تاريخ الاستخدام</th>
                  </tr>
                </thead>
                <tbody>
                  {licenses.map(lic => (
                    <tr key={lic.id}>
                      <td>
                        <code style={{ fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--primary)', letterSpacing: '1px' }}>
                          {lic.code}
                        </code>
                      </td>
                      <td>
                        <span className={`badge ${
                          lic.status === 'active' ? 'badge-success' : 
                          lic.status === 'used' ? 'badge-pending' : 'badge-danger'
                        }`}>
                          {lic.status === 'active' ? 'متاح للتفعيل' : 
                           lic.status === 'used' ? 'مستخدَم' : 'منتهي / ملغي'}
                        </span>
                      </td>
                      <td>
                        {lic.status === 'used' ? (
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <ShieldCheck size={16} style={{ color: '#10b981' }} />
                            <span>{lic.used_by_profile?.full_name || 'مستخدم غير معروف'}</span>
                          </div>
                        ) : '—'}
                      </td>
                      <td>{lic.used_at ? new Date(lic.used_at).toLocaleDateString('ar-IQ') : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Creation Modal */}
      {showModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '100%', maxWidth: '480px', padding: '32px' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '24px' }}>توليد حزمة اشتراكات جديدة</h2>

            <form onSubmit={handleCreateBatch} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div className="form-group">
                <label className="form-label">خط الحافلة المرتبط</label>
                <select 
                  className="form-input" 
                  value={routeId}
                  onChange={(e) => setRouteId(e.target.value)}
                  required
                >
                  <option value="">اختر الخط المخصص للتراخيص...</option>
                  {routes.map(r => (
                    <option key={r.id} value={r.id}>{r.title}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">اسم الحزمة (مرجعي)</label>
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="مثال: حزمة الوجبة الصيفية" 
                  value={batchName}
                  onChange={(e) => setBatchName(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">عدد الرموز المطلوبة</label>
                  <input 
                    type="number" 
                    className="form-input" 
                    placeholder="100" 
                    value={quantity}
                    onChange={(e) => setQuantity(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">صلاحية التذكرة (أيام)</label>
                  <input 
                    type="number" 
                    className="form-input" 
                    placeholder="30" 
                    value={validDays}
                    onChange={(e) => setValidDays(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">السعر الفردي للرمز (د.ع)</label>
                <input 
                  type="number" 
                  className="form-input" 
                  placeholder="50000" 
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)} disabled={actionLoading}>
                  إلغاء
                </button>
                <button type="submit" className="btn btn-primary" disabled={actionLoading}>
                  {actionLoading ? 'جاري توليد التراخيص...' : 'توليد وتخزين الرموز'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
