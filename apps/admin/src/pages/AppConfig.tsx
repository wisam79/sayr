import React, { useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { Settings, Save, AlertTriangle, ShieldCheck } from 'lucide-react';
import { useToast } from '../components/Toast';

export const AppConfig: React.FC = () => {
  const { showToast } = useToast();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form State
  const [minVersion, setMinVersion] = useState('3.0.0');
  const [latestVersion, setLatestVersion] = useState('3.0.0');
  const [updateUrl, setUpdateUrl] = useState('');
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [maintenanceMessage, setMaintenanceMessage] = useState('');
  const [maintenanceMessageEn, setMaintenanceMessageEn] = useState('');
  const [supportEmail, setSupportEmail] = useState('');
  const [supportPhone, setSupportPhone] = useState('');
  const [termsUrl, setTermsUrl] = useState('');
  const [privacyUrl, setPrivacyUrl] = useState('');

  useEffect(() => {
    fetchConfig();
  }, []);

  async function fetchConfig() {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error: fetchError } = await supabase
        .from('app_config')
        .select('*')
        .eq('id', 1)
        .single();

      if (fetchError) throw fetchError;

      if (data) {
        setMinVersion(data.min_version);
        setLatestVersion(data.latest_version);
        setUpdateUrl(data.update_url || '');
        setMaintenanceMode(data.maintenance_mode);
        setMaintenanceMessage(data.maintenance_message || '');
        setMaintenanceMessageEn(data.maintenance_message_en || '');
        setSupportEmail(data.support_email || '');
        setSupportPhone(data.support_phone || '');
        setTermsUrl(data.terms_url || '');
        setPrivacyUrl(data.privacy_url || '');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل في تحميل إعدادات التطبيق العامة.';
      showToast('فشل في تحميل إعدادات التطبيق العامة', 'error');
      setError(message);
    } finally {
      setLoading(false);
    }
  }

  const handleSaveConfig = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);

    try {
      const { error: updateError } = await supabase
        .from('app_config')
        .update({
          min_version: minVersion,
          latest_version: latestVersion,
          update_url: updateUrl || null,
          maintenance_mode: maintenanceMode,
          maintenance_message: maintenanceMessage || null,
          maintenance_message_en: maintenanceMessageEn || null,
          support_email: supportEmail || null,
          support_phone: supportPhone || null,
          terms_url: termsUrl || null,
          privacy_url: privacyUrl || null,
        })
        .eq('id', 1);

      if (updateError) throw updateError;
      showToast('تم حفظ إعدادات النظام وتحديثها بنجاح!', 'success');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل في حفظ إعدادات المنصة';
      showToast(message, 'error');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="card shimmer-bg" style={{ height: '400px', border: 'none' }}></div>;
  }

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl', maxWidth: '800px', margin: '0 auto' }}>
      {error && (
        <div className="card" style={{ border: '1.5px solid var(--danger)', color: 'var(--danger)', marginBottom: '24px' }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSaveConfig} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        
        {/* Maintenance Config */}
        <div className="card card-premium">
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertTriangle size={20} style={{ color: 'var(--warning)' }} />
            <span>وضع الصيانة وإعلانات النظام</span>
          </h2>

          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
            <input 
              type="checkbox" 
              id="maintenanceMode" 
              checked={maintenanceMode}
              onChange={(e) => setMaintenanceMode(e.target.checked)}
            />
            <label htmlFor="maintenanceMode" className="form-label" style={{ marginBottom: 0, cursor: 'pointer', fontWeight: 600 }}>
              تفعيل وضع الصيانة العام (إيقاف تشغيل التطبيق مؤقتاً)
            </label>
          </div>

          <div className="form-group">
            <label className="form-label">رسالة الصيانة / التنبيه (باللغة العربية)</label>
            <textarea 
              className="form-input" 
              style={{ height: '90px', padding: '12px', resize: 'vertical' }}
              placeholder="نعمل حالياً على تحديث الخوادم لتجربة أفضل، سنعود خلال ساعة."
              value={maintenanceMessage}
              onChange={(e) => setMaintenanceMessage(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">رسالة الصيانة / التنبيه (باللغة الإنجليزية)</label>
            <textarea 
              className="form-input" 
              style={{ height: '90px', padding: '12px', resize: 'vertical' }}
              placeholder="We are updating our services. We will be back shortly."
              value={maintenanceMessageEn}
              onChange={(e) => setMaintenanceMessageEn(e.target.value)}
            />
          </div>
        </div>

        {/* Versions Control */}
        <div className="card">
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Settings size={20} style={{ color: 'var(--primary)' }} />
            <span>إدارة إصدارات الهواتف المحمولة</span>
          </h2>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">الحد الأدنى المطلوب للإصدار (Min Version)</label>
              <input 
                type="text" 
                className="form-input" 
                placeholder="3.0.0" 
                value={minVersion}
                onChange={(e) => setMinVersion(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">الإصدار الأخير المتوفر (Latest Version)</label>
              <input 
                type="text" 
                className="form-input" 
                placeholder="3.0.0" 
                value={latestVersion}
                onChange={(e) => setLatestVersion(e.target.value)}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">رابط صفحة التحميل / التحديث (Google Play URL)</label>
            <input 
              type="url" 
              className="form-input" 
              placeholder="https://play.google.com/store/apps/details?id=com.sayr.sayr_mobile" 
              value={updateUrl}
              onChange={(e) => setUpdateUrl(e.target.value)}
            />
          </div>
        </div>

        {/* Support Helplines */}
        <div className="card">
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ShieldCheck size={20} style={{ color: 'var(--primary)' }} />
            <span>بيانات الدعم الفني والروابط القانونية</span>
          </h2>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">البريد الإلكتروني للدعم</label>
              <input 
                type="email" 
                className="form-input" 
                placeholder="support@sayr.app" 
                value={supportEmail}
                onChange={(e) => setSupportEmail(e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">رقم هاتف الدعم (AsiaCell/Zain)</label>
              <input 
                type="text" 
                className="form-input" 
                placeholder="+9647700000000" 
                value={supportPhone}
                onChange={(e) => setSupportPhone(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">رابط شروط الاستخدام (Terms of Service)</label>
              <input 
                type="url" 
                className="form-input" 
                placeholder="https://sayr.app/terms" 
                value={termsUrl}
                onChange={(e) => setTermsUrl(e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">رابط سياسة الخصوصية (Privacy Policy)</label>
              <input 
                type="url" 
                className="form-input" 
                placeholder="https://sayr.app/privacy" 
                value={privacyUrl}
                onChange={(e) => setPrivacyUrl(e.target.value)}
              />
            </div>
          </div>
        </div>

        {/* Submit Actions */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
          <button type="submit" className="btn btn-primary" style={{ minWidth: '180px' }} disabled={saving}>
            <Save size={18} />
            <span>{saving ? 'جاري حفظ الإعدادات...' : 'حفظ إعدادات النظام'}</span>
          </button>
        </div>

      </form>
    </div>
  );
};
