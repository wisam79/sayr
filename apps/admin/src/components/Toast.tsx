import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useRef,
} from 'react';
import {
  CheckCircle,
  XCircle,
  AlertTriangle,
  Info,
  X,
} from 'lucide-react';
import './Toast.css';

/* ---------- Types ---------- */
type ToastType = 'success' | 'error' | 'warning' | 'info';

interface ToastItem {
  id: number;
  message: string;
  type: ToastType;
  exiting: boolean;
}

interface ToastContextValue {
  showToast: (message: string, type?: ToastType) => void;
}

/* ---------- Context ---------- */
const ToastContext = createContext<ToastContextValue | null>(null);

export const useToast = (): ToastContextValue => {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useToast يجب أن يُستخدم داخل ToastProvider');
  }
  return ctx;
};

/* ---------- Icon map ---------- */
const toastIcons: Record<ToastType, React.ElementType> = {
  success: CheckCircle,
  error: XCircle,
  warning: AlertTriangle,
  info: Info,
};

/* ---------- Auto-dismiss duration (ms) ---------- */
const TOAST_DURATION = 4000;
const EXIT_DURATION = 150; // matches --transition-fast

/* ---------- Provider ---------- */
export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const idRef = useRef(0);

  const removeToast = useCallback((id: number) => {
    // Mark as exiting first for the slide-out animation
    setToasts((prev) =>
      prev.map((t) => (t.id === id ? { ...t, exiting: true } : t)),
    );
    // Remove from DOM after exit animation completes
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, EXIT_DURATION);
  }, []);

  const showToast = useCallback(
    (message: string, type: ToastType = 'info') => {
      const id = ++idRef.current;
      setToasts((prev) => [...prev, { id, message, type, exiting: false }]);

      // Auto-dismiss
      setTimeout(() => removeToast(id), TOAST_DURATION);
    },
    [removeToast],
  );

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}

      {/* Render toast container */}
      <div className="toast-container" aria-live="polite">
        {toasts.map((toast) => {
          const Icon = toastIcons[toast.type];
          return (
            <div
              key={toast.id}
              className={`toast${toast.exiting ? ' toast--exiting' : ''}`}
              role="alert"
            >
              <div className={`toast-icon toast-icon--${toast.type}`}>
                <Icon size={20} />
              </div>
              <div className="toast-content">
                <p className="toast-message">{toast.message}</p>
              </div>
              <button
                className="toast-close"
                onClick={() => removeToast(toast.id)}
                aria-label="إغلاق"
              >
                <X size={16} />
              </button>
              <div className={`toast-progress toast-progress--${toast.type}`} />
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
};
