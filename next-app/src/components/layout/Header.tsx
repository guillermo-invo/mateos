'use client';

import { useTheme } from '../../context/ThemeContext';

export default function Header() {
  const { theme, toggleTheme } = useTheme();

  return (
    <header className="bg-white shadow p-4 flex justify-between items-center dark:bg-gray-900 dark:text-white">
      <h2 className="text-xl font-semibold">Dashboard</h2> {/* Dynamic title based on page */}
      <button onClick={toggleTheme} className="p-2 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700">
        {theme === 'dark' ? '☀️ Light Mode' : '🌙 Dark Mode'}
      </button>
    </header>
  );
}
