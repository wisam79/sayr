import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../utils/supabaseClient';
import { Lock, Mail, ShieldAlert } from 'lucide-react';
import './Login.css';

export const Login: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setErrorMessage('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setLoading(true);
    setErrorMessage(null);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw new Error(error.message === 'Invalid login credentials' 
          ? 'خطأ في البريد الإلكتروني أو كلمة المرور' 
          : error.message
        );
      }

      // Check if user has admin role after successful login
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', data.user.id)
        .single();

      if (profileError || !profile) {
        throw new Error('فشل في جلب صلاحيات الحساب الخاص بك.');
      }

      if (profile.role !== 'admin') {
        await supabase.auth.signOut();
        throw new Error('عذراً، هذا الحساب لا يمتلك صلاحيات المشرف (Admin).');
      }

      // Redirect to Dashboard on success
      navigate('/');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'حدث خطأ غير متوقع أثناء تسجيل الدخول';
      console.error('Login error:', err);
      setErrorMessage(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card card animate-fade-in">
        <div className="login-header">
          <div className="logo-icon-large">
            <svg viewBox="0 0 1024 1024" style={{ width: '100%', height: '100%', borderRadius: '12px' }}>
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
          </div>
          <h2>سير - لوحة التحكم</h2>
          <p>يرجى تسجيل الدخول للوصول إلى لوحة إدارة عمليات النقل</p>
        </div>

        <form onSubmit={handleLogin} className="login-form">
          {errorMessage && (
            <div className="login-error">
              <ShieldAlert size={20} />
              <span>{errorMessage}</span>
            </div>
          )}

          <div className="form-group">
            <label className="form-label" htmlFor="email">
              البريد الإلكتروني
            </label>
            <div className="input-with-icon">
              <Mail size={18} className="input-icon" />
              <input
                id="email"
                type="email"
                className="form-input"
                placeholder="admin@sayr.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="password">
              كلمة المرور
            </label>
            <div className="input-with-icon">
              <Lock size={18} className="input-icon" />
              <input
                id="password"
                type="password"
                className="form-input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                required
              />
            </div>
          </div>

          <button type="submit" className="btn btn-primary login-btn" disabled={loading}>
            {loading ? 'جاري التحقق من الحساب...' : 'تسجيل الدخول'}
          </button>
        </form>
      </div>
    </div>
  );
};
