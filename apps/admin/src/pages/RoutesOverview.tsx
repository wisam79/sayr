import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { Plus, Edit2, MapPin, DollarSign, Users } from 'lucide-react';
import { useToast } from '../components/Toast';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';

interface Driver {
  id: string;
  vehicle_model: string;
  vehicle_plate: string;
  profiles: {
    full_name: string;
    phone: string;
  };
}

interface Route {
  id: string;
  title: string;
  start_location: string;
  end_location: string;
  price: number;
  capacity: number;
  available_seats: number;
  departure_time: string | null;
  return_time: string | null;
  is_active: boolean;
  drivers: Driver | null;
}

export const RoutesOverview: React.FC = () => {
  const { showToast } = useToast();
  const [routes, setRoutes] = useState<Route[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);

  // ConfirmDialog State
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmMessage, setConfirmMessage] = useState('');
  
  // Form State
  const [editingRoute, setEditingRoute] = useState<Route | null>(null);
  const [title, setTitle] = useState('');
  const [startLocation, setStartLocation] = useState('');
  const [endLocation, setEndLocation] = useState('');
  const [price, setPrice] = useState('');
  const [capacity, setCapacity] = useState('');
  const [driverId, setDriverId] = useState('');
  const [departureTime, setDepartureTime] = useState('');
  const [returnTime, setReturnTime] = useState('');
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    fetchRoutes();
    fetchDrivers();
  }, []);

  const fetchRoutes = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('routes')
        .select(`
          *,
          drivers:driver_id (
            id,
            vehicle_model,
            vehicle_plate,
            profiles:user_id (
              full_name,
              phone
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const formattedData = (data as any[]).map(route => ({
        ...route,
        drivers: Array.isArray(route.drivers) ? route.drivers[0] : route.drivers
      }));

      setRoutes(formattedData);
    } catch (err) {
      showToast('فشل في جلب خطوط الحافلات', 'error');
    } finally {
      setLoading(false);
    }
  };

  const fetchDrivers = async () => {
    try {
      const { data, error } = await supabase
        .from('drivers')
        .select(`
          id,
          vehicle_model,
          vehicle_plate,
          profiles:user_id (
            full_name,
            phone
          )
        `)
        .eq('is_verified', true);

      if (error) throw error;
      
      const formattedDrivers = (data as any[]).map(driver => ({
        ...driver,
        profiles: Array.isArray(driver.profiles) ? driver.profiles[0] : driver.profiles
      }));

      setDrivers(formattedDrivers);
    } catch (err) {
      showToast('فشل في تحميل قائمة السائقين الموثقين', 'error');
    }
  };

  const openCreateModal = () => {
    setEditingRoute(null);
    setTitle('');
    setStartLocation('');
    setEndLocation('');
    setPrice('');
    setCapacity('');
    setDriverId('');
    setDepartureTime('');
    setReturnTime('');
    setIsActive(true);
    setShowModal(true);
  };

  const openEditModal = (route: Route) => {
    setEditingRoute(route);
    setTitle(route.title);
    setStartLocation(route.start_location);
    setEndLocation(route.end_location);
    setPrice(route.price.toString());
    setCapacity(route.capacity.toString());
    setDriverId(route.drivers?.id || '');
    setDepartureTime(route.departure_time || '');
    setReturnTime(route.return_time || '');
    setIsActive(route.is_active);
    setShowModal(true);
  };

  const handleSaveRoute = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !startLocation || !endLocation || !price || !capacity || !driverId) {
      showToast('الرجاء تعبئة جميع الحقول الأساسية', 'warning');
      return;
    }

    setActionLoading(true);

    const routeData = {
      title,
      start_location: startLocation,
      end_location: endLocation,
      price: parseFloat(price),
      capacity: parseInt(capacity),
      driver_id: driverId,
      departure_time: departureTime || null,
      return_time: returnTime || null,
      is_active: isActive,
    };

    try {
      if (editingRoute) {
        // Edit Route
        const seatDifference = parseInt(capacity) - editingRoute.capacity;
        const newAvailableSeats = Math.max(0, editingRoute.available_seats + seatDifference);

        const { error } = await supabase
          .from('routes')
          .update({
            ...routeData,
            available_seats: newAvailableSeats
          })
          .eq('id', editingRoute.id);

        if (error) throw error;
        showToast('تم تعديل تفاصيل خط الحافلة بنجاح', 'success');
      } else {
        // Create Route
        const { error } = await supabase
          .from('routes')
          .insert({
            ...routeData,
            available_seats: parseInt(capacity)
          });

        if (error) throw error;
        showToast('تم إنشاء خط الحافلة الجديد بنجاح', 'success');
      }

      setShowModal(false);
      fetchRoutes();
    } catch (err) {
      showToast('فشل في حفظ تفاصيل خط الحافلة', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const triggerToggleRouteState = (route: Route) => {
    const action = route.is_active ? 'تعطيل' : 'تفعيل';
    setConfirmMessage(`هل أنت متأكد من ${action} خط النقل "${route.title}"؟`);
    setConfirmAction(() => async () => {
      await handleToggleRouteState(route);
    });
    setConfirmOpen(true);
  };

  const handleToggleRouteState = async (route: Route) => {
    try {
      const nextActiveState = !route.is_active;
      const { error } = await supabase
        .from('routes')
        .update({ is_active: nextActiveState })
        .eq('id', route.id);

      if (error) throw error;

      setRoutes(prev => prev.map(r => r.id === route.id ? { ...r, is_active: nextActiveState } : r));
      showToast(nextActiveState ? 'تم تفعيل خط النقل بنجاح' : 'تم تعطيل خط النقل بنجاح', 'success');
    } catch (err) {
      showToast('فشل في تغيير حالة خط الحافلة', 'error');
    }
  };

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {/* Header and Add Button */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '24px' }}>
        <button className="btn btn-primary" onClick={openCreateModal}>
          <Plus size={18} />
          <span>إنشاء خط حافلة جديد</span>
        </button>
      </div>

      {/* Routes Grid */}
      {loading ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px' }}>
          {Array.from({ length: 3 }).map((_, idx) => (
            <div key={idx} className="card shimmer-bg" style={{ height: '220px', border: 'none' }}></div>
          ))}
        </div>
      ) : routes.length === 0 ? (
        <EmptyState
          icon={MapPin}
          title="لا توجد خطوط نقل مضافة حتى الآن"
          description="لم يتم العثور على أي خط نقل نشط أو معطل. يمكنك البدء بإنشاء خط نقل جديد."
          actionLabel="إنشاء خط حافلة جديد"
          onAction={openCreateModal}
        />
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px' }}>
          {routes.map((route) => (
            <div key={route.id} className="card card-premium" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '6px' }}>{route.title}</h3>
                  <span className={`badge ${route.is_active ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '0.7rem' }}>
                    {route.is_active ? 'نشط ويعمل' : 'متوقف مؤقتاً'}
                  </span>
                </div>
                <button 
                  className="btn btn-secondary" 
                  style={{ width: '36px', height: '36px', padding: 0 }}
                  onClick={() => openEditModal(route)}
                >
                  <Edit2 size={16} />
                </button>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <MapPin size={16} style={{ color: 'var(--primary)' }} />
                  <span><strong>من:</strong> {route.start_location} <strong>إلى:</strong> {route.end_location}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Users size={16} style={{ color: 'var(--primary)' }} />
                  <span><strong>المقاعد الشاغرة:</strong> {route.available_seats} / {route.capacity} مقعد</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <DollarSign size={16} style={{ color: 'var(--primary)' }} />
                  <span><strong>السعر:</strong> {route.price.toLocaleString('ar-IQ')} د.ع</span>
                </div>
              </div>

              <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '12px', fontSize: '0.8rem' }}>
                <strong>السائق المسؤول:</strong> {route.drivers?.profiles.full_name || 'غير محدد'} ({route.drivers?.vehicle_model || '—'} - {route.drivers?.vehicle_plate || '—'})
              </div>

              <div style={{ display: 'flex', gap: '10px', marginTop: 'auto' }}>
                <button 
                  className={`btn ${route.is_active ? 'btn-secondary' : 'btn-primary'}`} 
                  style={{ flex: 1, height: '36px', fontSize: '0.8rem' }}
                  onClick={() => triggerToggleRouteState(route)}
                >
                  {route.is_active ? 'تعطيل الخط' : 'تفعيل الخط'}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Edit/Create Modal (Standard Popup with Vanilla Backdrop CSS) */}
      {showModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '100%', maxWidth: '560px', padding: '32px', position: 'relative', overflowY: 'auto', maxHeight: '90vh' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '24px' }}>
              {editingRoute ? 'تعديل تفاصيل خط النقل' : 'إنشاء خط نقل جديد'}
            </h2>

            <form onSubmit={handleSaveRoute} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div className="form-group">
                <label className="form-label">اسم الخط (العنوان)</label>
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="مثال: خط جامعة بغداد - باب المعظم"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required 
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">نقطة الانطلاق</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    placeholder="مثال: الكرادة الشرقية"
                    value={startLocation}
                    onChange={(e) => setStartLocation(e.target.value)}
                    required 
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">نقطة الوصول</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    placeholder="مثال: مجمع باب المعظم"
                    value={endLocation}
                    onChange={(e) => setEndLocation(e.target.value)}
                    required 
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">سعر الاشتراك (د.ع)</label>
                  <input 
                    type="number" 
                    className="form-input" 
                    placeholder="50000"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    required 
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">سعة الركاب (المقاعد الكلية)</label>
                  <input 
                    type="number" 
                    className="form-input" 
                    placeholder="25"
                    value={capacity}
                    onChange={(e) => setCapacity(e.target.value)}
                    required 
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">السائق المعتمد للخط</label>
                <select 
                  className="form-input"
                  value={driverId}
                  onChange={(e) => setDriverId(e.target.value)}
                  required
                >
                  <option value="">اختر سائقاً موثقاً...</option>
                  {drivers.map(driver => (
                    <option key={driver.id} value={driver.id}>
                      {driver.profiles.full_name} ({driver.vehicle_model} - {driver.vehicle_plate})
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">وقت الانطلاق صباحاً</label>
                  <input 
                    type="time" 
                    className="form-input" 
                    value={departureTime}
                    onChange={(e) => setDepartureTime(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">وقت العودة عصراً</label>
                  <input 
                    type="time" 
                    className="form-input" 
                    value={returnTime}
                    onChange={(e) => setReturnTime(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                <input 
                  type="checkbox" 
                  id="isActive"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                />
                <label htmlFor="isActive" className="form-label" style={{ marginBottom: 0, cursor: 'pointer' }}>تفعيل الخط للجمهور فوراً</label>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)} disabled={actionLoading}>
                  إلغاء
                </button>
                <button type="submit" className="btn btn-primary" disabled={actionLoading}>
                  {actionLoading ? 'جاري الحفظ...' : 'حفظ الخط'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmOpen}
        title="تأكيد العملية"
        message={confirmMessage}
        variant="warning"
        confirmLabel="نعم، متأكد"
        cancelLabel="تراجع"
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
