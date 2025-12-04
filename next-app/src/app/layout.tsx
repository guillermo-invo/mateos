import type { Metadata } from 'next';
import { Inter } from 'next/font/google'; // Assuming Inter is used or a similar font
import './globals.css'; // Assuming this is the global CSS file
import { HeroUIProvider } from '@heroui/react';

import Sidebar from '../components/layout/Sidebar';
import Header from '../components/layout/Header';
import Footer from '../components/layout/Footer';
import { ThemeProvider } from '../context/ThemeContext';

const inter = Inter({ subsets: ['latin'] }); // Initialize font

export const metadata: Metadata = {
  title: 'MATEOS V2 - Gestión Estratégica',
  description: 'Sistema de Gestión Estratégica personal con IA',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es" className={inter.className}>
      <body>
        <ThemeProvider>
          <HeroUIProvider>
            <div className="flex min-h-screen bg-gray-100 dark:bg-gray-950">
              <Sidebar />
              <div className="flex flex-col flex-1">
                <Header />
                <main className="flex-1 p-6">
                  {children}
                </main>
                <Footer />
              </div>
            </div>
          </HeroUIProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}