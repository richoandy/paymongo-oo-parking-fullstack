import type { ReactNode } from 'react';
import './Card.css';

export function Card({ children, title, className = '' }: { children: ReactNode; title?: string; className?: string }) {
  return (
    <div className={`card ${className}`}>
      {title && <h3 className="card-title">{title}</h3>}
      {children}
    </div>
  );
}
