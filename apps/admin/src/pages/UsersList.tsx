import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { Search, Check, X, Star, Calendar, User, Phone, Bus, FileText, Users, Shield } from 'lucide-react';
import { useToast } from '../components/Toast';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';

interface Profile {
  id: string;
  full_name: string;
  phone: string;
  role: string;
  is_verified: boolean;
  created_at: string;
  drivers?: {
    id: string;
    vehicle_model: string;
    vehicle_plate: string;
    capacity: number;
    license_number: string;
    is_verified: boolean;
    rating: number;
    total_trips: number;
  } | null;
}

interface Rating {
  id: string;
  rating: number;
  comment: string | null;
  created_at: string;
  profiles: {
    full_name: string;
    phone: string;
  } | null;
}

export const UsersList: React.FC = () => {
  const { showToast } = useToast();
  const [users, setUsers] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'student' | 'driver' | 'admin'>('all');
  const [verificationFilter, setVerificationFilter] = useState<'all' | 'verified' | 'unverified'>('all');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // ConfirmDialog state
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmMessage, setConfirmMessage] = useState('');

  // Inspector Modal State
  const [inspectingDriver, setInspectingDriver] = useState<Profile | null>(null);
  const [ratings, setRatings] = useState<Rating[]>([]);
  const [ratingsLoading, setRatingsLoading] = useState(false);

  // Promote to Driver Modal State
  const [driverModalOpen, setDriverModalOpen] = useState(false);
  const [promotingUser, setPromotingUser] = useState<Profile | null>(null);
  const [vehicleModel, setVehicleModel] = useState('');
  const [vehiclePlate, setVehiclePlate] = useState('');
  const [capacity, setCapacity] = useState('14');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [licenseExpiry, setLicenseExpiry] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      // Fetch profiles and join drivers
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          full_name,
          phone,
          role,
          is_verified,
          created_at,
          drivers (
            id,
            vehicle_model,
            vehicle_plate,
            capacity,
            license_number,
            is_verified,
            rating,
            total_trips
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      // Flatten drivers if it comes back as array (Supabase handles relationships)
      const formattedData = (data as any[]).map(profile => ({
        ...profile,
        drivers: Array.isArray(profile.drivers) ? profile.drivers[0] : profile.drivers
      }));

      setUsers(formattedData);
    } catch (err) {
      showToast('فشل في جلب بيانات المستخدمين', 'error');
    } finally {
      setLoading(false);
    }
  };

  const triggerToggleVerification = (profile: Profile) => {
    const action = profile.is_verified ? 'إلغاء توثيق' : 'توثيق';
    setConfirmMessage(`هل أنت متأكد من ${action} حساب "${profile.full_name || 'هذا المستخدم'}"؟`);
    setConfirmAction(() => async () => {
      await handleToggleVerification(profile);
    });
    setConfirmOpen(true);
  };

  const handleToggleVerification = async (profile: Profile) => {
    const nextVerifiedState = !profile.is_verified;
    setActionLoadingId(profile.id);

    try {
      // 1. Update Profile verification status
      const { error: profileError } = await supabase
        .from('profiles')
        .update({ is_verified: nextVerifiedState })
        .eq('id', profile.id);

      if (profileError) throw profileError;

      // 2. If user is a driver, also update Drivers table verification
      if (profile.role === 'driver' && profile.drivers) {
        const { error: driverError } = await supabase
          .from('drivers')
          .update({ is_verified: nextVerifiedState })
          .eq('id', profile.drivers.id);

        if (driverError) throw driverError;
      }

      // Update local state
      setUsers(prev => prev.map(u => {
        if (u.id === profile.id) {
          return {
            ...u,
            is_verified: nextVerifiedState,
            drivers: u.drivers ? { ...u.drivers, is_verified: nextVerifiedState } : null
          };
        }
        return u;
      }));

      // Update inspector state if active
      if (inspectingDriver && inspectingDriver.id === profile.id) {
        setInspectingDriver(prev => prev ? {
          ...prev,
          is_verified: nextVerifiedState,
          drivers: prev.drivers ? { ...prev.drivers, is_verified: nextVerifiedState } : null
        } : null);
      }

      showToast(
        nextVerifiedState ? 'تم توثيق الحساب بنجاح' : 'تم إلغاء توثيق الحساب',
        'success'
      );
    } catch (err) {
      showToast('فشل في تعديل حالة التحقق', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleInspectDriver = async (driverProfile: Profile) => {
    if (!driverProfile.drivers) return;
    setInspectingDriver(driverProfile);
    setRatingsLoading(true);
    setRatings([]);
    try {
      const { data, error } = await supabase
        .from('ratings')
        .select(`
          id,
          rating,
          comment,
          created_at,
          profiles:student_id (
            full_name,
            phone
          )
        `)
        .eq('driver_id', driverProfile.drivers.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const formatted: Rating[] = (data as any[]).map(r => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        created_at: r.created_at,
        profiles: Array.isArray(r.profiles) ? r.profiles[0] : r.profiles
      }));

      setRatings(formatted);
    } catch (err) {
      showToast('فشل في جلب تقييمات السائق', 'error');
    } finally {
      setRatingsLoading(false);
    }
  };

  const closeInspector = () => {
    setInspectingDriver(null);
    setRatings([]);
  };

  const handlePromoteToAdmin = async (profile: Profile) => {
    setActionLoadingId(profile.id);
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ role: 'admin' })
        .eq('id', profile.id);

      if (error) throw error;

      setUsers(prev => prev.map(u => {
        if (u.id === profile.id) {
          return { ...u, role: 'admin' };
        }
        return u;
      }));

      showToast(`تمت ترقية "${profile.full_name || 'المستخدم'}" إلى مسؤول بنجاح`, 'success');
    } catch (err) {
      showToast('فشل في الترقية إلى مسؤول', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const triggerPromoteToAdmin = (profile: Profile) => {
    setConfirmMessage(`هل أنت متأكد من تعيين "${profile.full_name || 'هذا المستخدم'}" كمسؤول؟ سيحصل على كامل صلاحيات الإدارة.`);
    setConfirmAction(() => async () => {
      await handlePromoteToAdmin(profile);
    });
    setConfirmOpen(true);
  };

  const handleDemoteAdmin = async (profile: Profile) => {
    setActionLoadingId(profile.id);
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ role: 'student' })
        .eq('id', profile.id);

      if (error) throw error;

      setUsers(prev => prev.map(u => {
        if (u.id === profile.id) {
          return { ...u, role: 'student' };
        }
        return u;
      }));

      showToast(`تم إلغاء صلاحيات المسؤول للمستخدم "${profile.full_name || 'المستخدم'}"`, 'success');
    } catch (err) {
      showToast('فشل في إلغاء صلاحيات المسؤول', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const triggerDemoteAdmin = (profile: Profile) => {
    setConfirmMessage(`هل أنت متأكد من إلغاء صلاحيات المسؤول للمستخدم "${profile.full_name || 'هذا المستخدم'}" وتحويله إلى طالب؟`);
    setConfirmAction(() => async () => {
      await handleDemoteAdmin(profile);
    });
    setConfirmOpen(true);
  };

  const handleDemoteDriver = async (profile: Profile) => {
    setActionLoadingId(profile.id);
    try {
      // Deleting driver from drivers table.
      // Trigger sync_driver_role_demotion will automatically update profiles.role = 'student' and raw_app_meta_data.
      const { error } = await supabase
        .from('drivers')
        .delete()
        .eq('user_id', profile.id);

      if (error) throw error;

      setUsers(prev => prev.map(u => {
        if (u.id === profile.id) {
          return { ...u, role: 'student', drivers: null };
        }
        return u;
      }));

      showToast(`تم تنزيل "${profile.full_name || 'المستخدم'}" إلى طالب بنجاح وحذف معلومات المركبة`, 'success');
    } catch (err) {
      showToast('فشل في تنزيل السائق إلى طالب', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const triggerDemoteDriver = (profile: Profile) => {
    setConfirmMessage(`هل أنت متأكد من تنزيل السائق "${profile.full_name || 'هذا السائق'}" إلى طالب؟ سيتم حذف بيانات مركبته بالكامل.`);
    setConfirmAction(() => async () => {
      await handleDemoteDriver(profile);
    });
    setConfirmOpen(true);
  };

  const handlePromoteToDriverSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!promotingUser) return;

    setActionLoadingId(promotingUser.id);
    try {
      const parsedCapacity = parseInt(capacity, 10);
      if (isNaN(parsedCapacity) || parsedCapacity <= 0) {
        showToast('يرجى إدخال حمولة صالحة للمركبة', 'error');
        return;
      }

      // Insert into drivers table
      // Trigger sync_driver_role_promotion will automatically update profiles.role = 'driver' and raw_app_meta_data
      const { data, error } = await supabase
        .from('drivers')
        .insert({
          user_id: promotingUser.id,
          vehicle_model: vehicleModel,
          vehicle_plate: vehiclePlate,
          capacity: parsedCapacity,
          license_number: licenseNumber || null,
          license_expiry: licenseExpiry || null,
          is_verified: true // Promote with active verification directly
        })
        .select();

      if (error) throw error;

      const newDriver = data && data[0];

      setUsers(prev => prev.map(u => {
        if (u.id === promotingUser.id) {
          return {
            ...u,
            role: 'driver',
            drivers: {
              id: newDriver.id,
              vehicle_model: vehicleModel,
              vehicle_plate: vehiclePlate,
              capacity: parsedCapacity,
              license_number: licenseNumber,
              is_verified: true,
              rating: 0,
              total_trips: 0
            }
          };
        }
        return u;
      }));

      showToast(`تمت ترقية "${promotingUser.full_name || 'المستخدم'}" إلى سائق بنجاح`, 'success');
      setDriverModalOpen(false);
      setPromotingUser(null);
      setVehicleModel('');
      setVehiclePlate('');
      setCapacity('14');
      setLicenseNumber('');
      setLicenseExpiry('');
    } catch (err: unknown) {
      if (err instanceof Error && 'code' in err && (err as any).code === '23505') {
        showToast('رقم لوحة المركبة مسجل بالفعل لمركبة أخرى', 'error');
      } else {
        showToast('فشل في الترقية إلى سائق', 'error');
      }
    } finally {
      setActionLoadingId(null);
    }
  };

  // Filter logic
  const filteredUsers = users.filter(user => {
    const matchesSearch = 
      (user.full_name?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (user.phone || '').includes(searchTerm);
      
    const matchesRole = roleFilter === 'all' || user.role === roleFilter;
    
    const matchesVerification = 
      verificationFilter === 'all' || 
      (verificationFilter === 'verified' && user.is_verified) ||
      (verificationFilter === 'unverified' && !user.is_verified);

    return matchesSearch && matchesRole && matchesVerification;
  });

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl' }}>
      {/* Filters Card */}
      <div className="card" style={{ marginBottom: '24px', display: 'flex', flexWrap: 'wrap', gap: '16px', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ position: 'relative', minWidth: '280px' }}>
          <Search size={18} style={{ position: 'absolute', top: '50%', right: '12px', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
          <input 
            type="text" 
            className="form-input" 
            placeholder="البحث بالاسم أو الهاتف..." 
            style={{ paddingRight: '40px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>النوع:</span>
            <select 
              className="form-input" 
              style={{ width: '130px', height: '38px', padding: '0 8px' }}
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value as any)}
            >
              <option value="all">الكل</option>
              <option value="student">الطلاب</option>
              <option value="driver">السائقين</option>
              <option value="admin">المسؤولين</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>الحالة:</span>
            <select 
              className="form-input" 
              style={{ width: '130px', height: '38px', padding: '0 8px' }}
              value={verificationFilter}
              onChange={(e) => setVerificationFilter(e.target.value as any)}
            >
              <option value="all">الكل</option>
              <option value="verified">موثق</option>
              <option value="unverified">غير موثق</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      {loading ? (
        <div className="card shimmer-bg" style={{ height: '300px', border: 'none' }}></div>
      ) : filteredUsers.length === 0 ? (
        <EmptyState icon={Users} title="لا يوجد مستخدمون" description="لم يتم العثور على أي مستخدمين يطابقون خيارات البحث الحالية." />
      ) : (
        <div className="table-container">
          <table className="table-raw">
            <thead>
              <tr>
                <th>المستخدم</th>
                <th>رقم الهاتف</th>
                <th>نوع الحساب</th>
                <th>تفاصيل السائق (إن وجدت)</th>
                <th>حالة التوثيق</th>
                <th>تاريخ الانضمام</th>
                <th>الإجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user) => (
                <tr key={user.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{
                        width: '36px',
                        height: '36px',
                        borderRadius: '50%',
                        backgroundColor: 'var(--bg-tertiary)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: '600',
                        fontSize: '0.85rem'
                      }}>
                        {user.full_name?.substring(0, 1) || 'U'}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600 }}>{user.full_name || 'بدون اسم'}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>ID: {user.id.substring(0, 8)}</div>
                      </div>
                    </div>
                  </td>
                  <td>{user.phone || '—'}</td>
                  <td>
                    <span className={`badge ${
                      user.role === 'driver' 
                        ? 'badge-warning' 
                        : user.role === 'admin' 
                          ? 'badge-danger' 
                          : 'badge-active'
                    }`}>
                      {user.role === 'driver' ? 'سائق حافلة' : user.role === 'admin' ? 'مسؤول' : 'طالب'}
                    </span>
                  </td>
                  <td>
                    {user.role === 'driver' && user.drivers ? (
                      <div style={{ fontSize: '0.8rem', lineHeight: '1.4' }}>
                        <div><strong>الحافلة:</strong> {user.drivers.vehicle_model}</div>
                        <div><strong>اللوحة:</strong> {user.drivers.vehicle_plate}</div>
                        <div><strong>الحمولة:</strong> {user.drivers.capacity} راكب</div>
                      </div>
                    ) : (
                      <span style={{ color: 'var(--text-tertiary)', fontSize: '0.8rem' }}>—</span>
                    )}
                  </td>
                  <td>
                    <span className={`badge ${user.is_verified ? 'badge-success' : 'badge-danger'}`}>
                      {user.is_verified ? 'حساب موثق' : 'غير موثق'}
                    </span>
                  </td>
                  <td>{new Date(user.created_at).toLocaleDateString('ar-IQ')}</td>
                  <td>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', alignItems: 'center' }}>
                      {/* Common Toggle Verification for Student and Driver */}
                      {user.role !== 'admin' && (
                        <button
                          className={`btn ${user.is_verified ? 'btn-secondary' : 'btn-primary'}`}
                          style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px' }}
                          onClick={() => triggerToggleVerification(user)}
                          disabled={actionLoadingId === user.id}
                        >
                          {actionLoadingId === user.id ? 'جاري التعديل...' : (
                            user.is_verified ? (
                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--danger)' }}>
                                <X size={14} /> إلغاء التوثيق
                              </span>
                            ) : (
                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <Check size={14} /> توثيق الحساب
                              </span>
                            )
                          )}
                        </button>
                      )}

                      {/* Student Actions */}
                      {user.role === 'student' && (
                        <>
                          <button
                            className="btn btn-secondary"
                            style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px', display: 'flex', alignItems: 'center', gap: '4px', borderColor: 'var(--primary)', color: 'var(--primary)' }}
                            onClick={() => {
                              setPromotingUser(user);
                              setDriverModalOpen(true);
                            }}
                            disabled={actionLoadingId === user.id}
                          >
                            <Bus size={14} /> ترقية لسائق
                          </button>
                          
                          <button
                            className="btn btn-secondary"
                            style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px', display: 'flex', alignItems: 'center', gap: '4px' }}
                            onClick={() => triggerPromoteToAdmin(user)}
                            disabled={actionLoadingId === user.id}
                          >
                            <Shield size={14} /> تعيين كمسؤول
                          </button>
                        </>
                      )}

                      {/* Driver Actions */}
                      {user.role === 'driver' && (
                        <>
                          {user.drivers && (
                            <button
                              className="btn btn-secondary"
                              style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px', borderColor: 'var(--primary)', color: 'var(--primary)' }}
                              onClick={() => handleInspectDriver(user)}
                            >
                              معاينة التقييمات
                            </button>
                          )}
                          <button
                            className="btn btn-danger"
                            style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px', display: 'flex', alignItems: 'center', gap: '4px' }}
                            onClick={() => triggerDemoteDriver(user)}
                            disabled={actionLoadingId === user.id}
                          >
                            تنزيل لطالب
                          </button>
                        </>
                      )}

                      {/* Admin Actions */}
                      {user.role === 'admin' && (
                        <button
                          className="btn btn-danger"
                          style={{ height: '32px', fontSize: '0.8rem', padding: '0 12px', display: 'flex', alignItems: 'center', gap: '4px' }}
                          onClick={() => triggerDemoteAdmin(user)}
                          disabled={actionLoadingId === user.id}
                        >
                          <Shield size={14} /> إلغاء المسؤولية
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

      {/* Driver Ratings Inspector Modal */}
      {inspectingDriver && inspectingDriver.drivers && (
        <div className="modal-overlay" onClick={closeInspector}>
          <div className="modal-content" style={{ maxWidth: '640px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>تقارير وتقييمات السائق</h2>
              <button className="close-btn" onClick={closeInspector}><X size={18} /></button>
            </div>

            <div className="modal-body" style={{ maxHeight: '70vh', overflowY: 'auto', paddingRight: '4px' }}>
              {/* Driver Stats Header Card */}
              <div className="card" style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', padding: '16px', marginBottom: '20px' }}>
                <div style={{ flex: 1, minWidth: '200px' }}>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <User size={18} style={{ color: 'var(--primary)' }} />
                    {inspectingDriver.full_name}
                  </h3>
                  <p style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '6px' }}>
                    <Phone size={14} /> {inspectingDriver.phone || 'بدون رقم هاتف'}
                  </p>
                  <p style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                    <Calendar size={14} /> انضم في: {new Date(inspectingDriver.created_at).toLocaleDateString('ar-IQ')}
                  </p>
                </div>

                <div style={{ flex: 1, minWidth: '200px', display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '0.85rem', color: 'var(--text-secondary)', borderRight: '1px solid var(--border-color)', paddingRight: '16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><Bus size={14} /> <strong>الحافلة:</strong> {inspectingDriver.drivers.vehicle_model}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><strong>رقم اللوحة:</strong> {inspectingDriver.drivers.vehicle_plate}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><FileText size={14} /> <strong>رقم الترخيص:</strong> {inspectingDriver.drivers.license_number || 'غير متوفر'}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><strong>الحمولة القصوى:</strong> {inspectingDriver.drivers.capacity} راكب</div>
                </div>

                <div style={{ width: '100%', borderTop: '1px solid var(--border-color)', paddingTop: '12px', marginTop: '4px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>معدل التقييم:</span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 700, fontSize: '1.1rem', color: '#f59e0b' }}>
                      <Star size={18} fill="#f59e0b" color="#f59e0b" />
                      {Number(inspectingDriver.drivers.rating || 0).toFixed(2)} / 5.00
                    </span>
                  </div>
                  <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                    الرحلات المقيّمة: <strong style={{ color: 'var(--text-primary)' }}>{inspectingDriver.drivers.total_trips || 0}</strong>
                  </div>
                </div>
              </div>

              {/* Reviews List */}
              <h3 style={{ fontSize: '1rem', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '12px' }}>سجل تعليقات وتقييمات الطلاب</h3>
              
              {ratingsLoading ? (
                <div style={{ padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>جاري تحميل التقييمات...</div>
              ) : ratings.length === 0 ? (
                <div style={{ padding: '20px', textAlign: 'center', color: 'var(--text-secondary)', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                  لا توجد تقييمات أو تعليقات مسجلة لهذا السائق بعد.
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {ratings.map((r) => (
                    <div key={r.id} className="card" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <div style={{
                            width: '28px',
                            height: '28px',
                            borderRadius: '50%',
                            backgroundColor: 'var(--bg-tertiary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '600',
                            fontSize: '0.75rem'
                          }}>
                            {r.profiles?.full_name?.substring(0, 1) || 'S'}
                          </div>
                          <div>
                            <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>{r.profiles?.full_name || 'طالب مجهول'}</div>
                          </div>
                        </div>

                        <div style={{ display: 'flex', gap: '2px' }}>
                          {Array.from({ length: 5 }).map((_, idx) => (
                            <Star 
                              key={idx} 
                              size={14} 
                              fill={idx < r.rating ? '#f59e0b' : 'none'} 
                              color={idx < r.rating ? '#f59e0b' : 'var(--text-tertiary)'} 
                            />
                          ))}
                        </div>
                      </div>

                      {r.comment ? (
                        <p style={{ fontSize: '0.85rem', color: 'var(--text-primary)', backgroundColor: 'var(--bg-secondary)', padding: '10px', borderRadius: '6px', margin: '4px 0 0 0', borderRight: '3px solid var(--primary)' }}>
                          "{r.comment}"
                        </p>
                      ) : (
                        <p style={{ fontSize: '0.8rem', color: 'var(--text-tertiary)', fontStyle: 'italic', margin: '4px 0 0 0' }}>
                          تم التقييم بدون تعليق مكتوب.
                        </p>
                      )}

                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '4px' }}>
                        <span>الهاتف: {r.profiles?.phone || 'غير متوفر'}</span>
                        <span>{new Date(r.created_at).toLocaleDateString('ar-IQ')}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="modal-footer" style={{ marginTop: '20px' }}>
              <button type="button" className="btn btn-secondary" onClick={closeInspector}>إغلاق المعاينة</button>
              
              <button 
                type="button" 
                className={`btn ${inspectingDriver.is_verified ? 'btn-secondary' : 'btn-primary'}`}
                onClick={() => triggerToggleVerification(inspectingDriver)}
                disabled={actionLoadingId === inspectingDriver.id}
                style={{ color: inspectingDriver.is_verified ? 'var(--danger)' : '#ffffff', borderColor: inspectingDriver.is_verified ? 'var(--danger)' : 'var(--primary)' }}
              >
                {actionLoadingId === inspectingDriver.id ? 'جاري التعديل...' : (
                  inspectingDriver.is_verified ? 'إلغاء توثيق السائق' : 'توثيق السائق الآن'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Promote to Driver Modal */}
      {driverModalOpen && promotingUser && (
        <div className="modal-overlay" onClick={() => { setDriverModalOpen(false); setPromotingUser(null); }}>
          <div className="modal-content" style={{ maxWidth: '500px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>ترقية المستخدم إلى سائق حافلة</h2>
              <button className="close-btn" onClick={() => { setDriverModalOpen(false); setPromotingUser(null); }}><X size={18} /></button>
            </div>

            <form onSubmit={handlePromoteToDriverSubmit}>
              <div className="modal-body" style={{ maxHeight: '70vh', overflowY: 'auto', paddingLeft: '4px', paddingRight: '4px' }}>
                <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', marginBottom: '16px' }}>
                  أنت تقوم بترقية <strong>{promotingUser.full_name}</strong> إلى سائق. يرجى إدخال تفاصيل المركبة والترخيص أدناه:
                </p>

                <div className="form-group">
                  <label className="form-label">موديل ونوع المركبة (مثل: كيا بيستيا 2018)</label>
                  <input
                    type="text"
                    className="form-input"
                    required
                    value={vehicleModel}
                    onChange={(e) => setVehicleModel(e.target.value)}
                    placeholder="مثال: تويوتا كوستر 2020"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">رقم اللوحة</label>
                  <input
                    type="text"
                    className="form-input"
                    required
                    value={vehiclePlate}
                    onChange={(e) => setVehiclePlate(e.target.value)}
                    placeholder="مثال: 12345 بغداد أ"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">الحمولة القصوى (عدد الركاب)</label>
                  <input
                    type="number"
                    className="form-input"
                    required
                    min="1"
                    value={capacity}
                    onChange={(e) => setCapacity(e.target.value)}
                    placeholder="مثال: 14"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">رقم رخصة القيادة (اختياري)</label>
                  <input
                    type="text"
                    className="form-input"
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    placeholder="مثال: DL-987654"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">تاريخ انتهاء الرخصة (اختياري)</label>
                  <input
                    type="date"
                    className="form-input"
                    value={licenseExpiry}
                    onChange={(e) => setLicenseExpiry(e.target.value)}
                  />
                </div>
              </div>

              <div className="modal-footer" style={{ marginTop: '20px', display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => { setDriverModalOpen(false); setPromotingUser(null); }}
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={actionLoadingId === promotingUser.id}
                >
                  {actionLoadingId === promotingUser.id ? 'جاري الترقية...' : 'ترقية وتفعيل الحساب'}
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
        variant="danger"
        confirmLabel="نعم، تأكيد"
        cancelLabel="إلغاء"
        onConfirm={async () => { await confirmAction?.(); setConfirmOpen(false); }}
        onCancel={() => setConfirmOpen(false)}
      />
    </div>
  );
};
