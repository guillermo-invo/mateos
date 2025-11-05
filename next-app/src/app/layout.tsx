import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Transcripción API',
  description: 'API de transcripción para bot de Telegram',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
