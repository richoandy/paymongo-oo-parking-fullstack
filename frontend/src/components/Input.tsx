import type { InputHTMLAttributes, SelectHTMLAttributes } from 'react';
import './Input.css';

export function Input({ label, ...props }: { label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="field">
      <label>{label}</label>
      <input {...props} />
    </div>
  );
}

export function Select({
  label,
  options,
  ...props
}: { label: string; options: { value: string; label: string }[] } & SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <div className="field">
      <label>{label}</label>
      <select {...props}>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}
