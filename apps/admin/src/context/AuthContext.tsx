import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import type { User } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  role: string | null;
  loading: boolean;
  error: string | null;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // 1. Get initial session
    const initSession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session) {
          await checkUserRole(session.user);
        } else {
          setLoading(false);
        }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'فشل الاتصال بخدمة التحقق';
        console.error('Error initializing auth session:', err);
        setError(message);
        setLoading(false);
      }
    };

    initSession();

    // 2. Listen to Auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (session) {
        await checkUserRole(session.user);
      } else {
        setUser(null);
        setRole(null);
        setLoading(false);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const checkUserRole = async (currentUser: User) => {
    try {
      setError(null);
      // Fetch role from profile table
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUser.id)
        .single();

      if (profileError || !profile) {
        throw new Error(profileError?.message || 'لم يتم العثور على الملف الشخصي للمستخدم.');
      }

      if (profile.role !== 'admin') {
        // Automatically sign out if not admin
        await supabase.auth.signOut();
        throw new Error('عذراً، هذا الحساب لا يمتلك صلاحيات المشرف (Admin).');
      }

      setUser(currentUser);
      setRole(profile.role);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل التحقق من صلاحيات الحساب';
      console.error('RBAC validation failed:', err);
      setError(message);
      setUser(null);
      setRole(null);
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    setLoading(true);
    await supabase.auth.signOut();
    setUser(null);
    setRole(null);
    setLoading(false);
  };

  return (
    <AuthContext.Provider value={{ user, role, loading, error, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
