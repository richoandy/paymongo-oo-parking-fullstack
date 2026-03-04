import type { ButtonHTMLAttributes, ReactNode } from 'react';
import './Button.css';

type Variant = 'primary' | 'secondary' | 'success' | 'danger';

export function Button({
  children,
  variant = 'primary',
  className = '',
  ...props
}: { children: ReactNode; variant?: Variant } & ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button className={`btn btn-${variant} ${className}`} {...props}>
      {children}
    </button>
  );
}
