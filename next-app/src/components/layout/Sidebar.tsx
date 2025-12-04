'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/proyectos/dashboard', label: 'Sprint Actual' },
  { href: '/proyectos', label: 'Proyectos Estratégicos' },
  { href: '/tareas', label: 'Tareas Estratégicas' },
  { href: '/matarife', label: 'Vista Matarife' },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-gray-800 text-white p-4 min-h-screen">
      <h1 className="text-2xl font-bold mb-6">MATEOS V2</h1>
      <nav>
        <ul>
          {navItems.map((item) => (
            <li key={item.href} className="mb-2">
              <Link href={item.href} className={`block p-2 rounded ${pathname === item.href ? 'bg-gray-700' : 'hover:bg-gray-700'}`}>
                {item.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </aside>
  );
}
