import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import './Layout.css';

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="layout">
      <header className="header">
        <Link to="/" className="logo">
          <span className="logo-icon">◉</span>
          <span>OO Parking</span>
        </Link>
        <nav className="nav">
          <Link to="/">Dashboard</Link>
        </nav>
      </header>
      <main className="main">{children}</main>
    </div>
  );
}
