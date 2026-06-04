import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { AlertTriangle, ShieldAlert } from 'lucide-react';

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  variant?: 'danger' | 'warning';
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm: () => Promise<void> | void;
  onCancel: () => void;
}

export const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  isOpen,
  title,
  message,
  variant = 'danger',
  confirmLabel = 'تأكيد',
  cancelLabel = 'إلغاء',
  onConfirm,
  onCancel,
}) => {
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleConfirm = async () => {
    setLoading(true);
    try {
      await onConfirm();
    } finally {
      setLoading(false);
    }
  };

  const iconColor = variant === 'danger' ? 'var(--danger, #ef4444)' : 'var(--warning, #f59e0b)';
  const iconBg = variant === 'danger' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)';
  const Icon = variant === 'danger' ? ShieldAlert : AlertTriangle;

  return createPortal(
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        backdropFilter: 'blur(4px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 10000,
        direction: 'rtl',
        animation: 'fadeIn 0.2s ease forwards',
      }}
      onClick={loading ? undefined : onCancel}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          backgroundColor: 'var(--bg-secondary, #fff)',
          border: '1px solid var(--border-color, #e2e8f0)',
          borderRadius: 'var(--radius-md, 12px)',
          padding: '28px',
          width: '100%',
          maxWidth: '420px',
          boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
          animation: 'fadeIn 0.25s ease forwards',
        }}
      >
        {/* Icon */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '16px' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: '50%',
            backgroundColor: iconBg,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: iconColor,
          }}>
            <Icon size={26} />
          </div>
        </div>

        {/* Title */}
        <h3 style={{
          fontSize: '1.1rem',
          fontWeight: 700,
          textAlign: 'center',
          marginBottom: '8px',
          color: 'var(--text-primary)',
        }}>
          {title}
        </h3>

        {/* Message */}
        <p style={{
          fontSize: '0.9rem',
          color: 'var(--text-secondary)',
          textAlign: 'center',
          marginBottom: '24px',
          lineHeight: 1.6,
        }}>
          {message}
        </p>

        {/* Actions */}
        <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
          <button
            className="btn btn-secondary"
            onClick={onCancel}
            disabled={loading}
            style={{ flex: 1, maxWidth: '160px' }}
          >
            {cancelLabel}
          </button>
          <button
            className={`btn ${variant === 'danger' ? 'btn-danger' : 'btn-primary'}`}
            onClick={handleConfirm}
            disabled={loading}
            style={{ flex: 1, maxWidth: '160px' }}
          >
            {loading ? 'جاري التنفيذ...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
};
