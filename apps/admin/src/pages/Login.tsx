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
    } catch (err: any) {
      console.error('Login error:', err);
      setErrorMessage(err.message || 'حدث خطأ غير متوقع أثناء تسجيل الدخول');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card card animate-fade-in">
        <div className="login-header">
          <div className="logo-icon-large">S</div>
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
