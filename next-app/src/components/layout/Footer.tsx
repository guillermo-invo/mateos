// next-app/src/components/layout/Footer.tsx
export default function Footer() {
  return (
    <footer className="bg-gray-200 p-4 text-center text-gray-600 dark:bg-gray-800 dark:text-gray-400">
      <p>&copy; {new Date().getFullYear()} MATEOS V2. All rights reserved.</p>
    </footer>
  );
}
